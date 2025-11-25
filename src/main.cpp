#include <iostream>
#include <thread>
#include <chrono>
#include <csignal>
#include <mutex>
#include <vector>
#include <string>
#include <map>
#include <fstream>
#include <random>
#include "httplib.h"
#include <nlohmann/json.hpp>

using json = nlohmann::json;

bool running = true;
std::mutex db_mutex;
const std::string DATA_DIR = "/root/spiralcoin/data/";
const std::string BLOCKCHAIN_FILE = DATA_DIR + "blockchain.json";
const std::string WALLETS_FILE = DATA_DIR + "wallets.json";
const std::string PRIMARY_ADDRESS = "0x928072b3A3A42e7dFD577a91167DfAa08f0E653E";

struct Transaction { std::string from,to,txid; int amount; };
struct Block { int height; std::string hash; std::vector<Transaction> txs; };

class StateDBImpl {
public:
    StateDBImpl() { loadState(); }

    void commit() { std::lock_guard<std::mutex> lock(db_mutex); saveState(); }
    int getBalance(const std::string &addr=PRIMARY_ADDRESS) { std::lock_guard<std::mutex> lock(db_mutex); return wallets[addr]; }
    int getBlockCount() { return blockHeight; }

    std::string getBlock(int height) {
        std::lock_guard<std::mutex> lock(db_mutex);
        if(blockchain.find(height)!=blockchain.end()) {
            json j;
            Block &b = blockchain[height];
            j["hash"] = b.hash;
            j["height"] = b.height;
            j["transactions"] = json::array();
            for(auto &tx : b.txs) j["transactions"].push_back({{"from",tx.from},{"to",tx.to},{"amount",tx.amount},{"txid",tx.txid}});
            return j.dump();
        }
        return "{\"error\":\"Block not found\"}";
    }

    std::string sendToAddress(const std::string &to, int amount) {
        std::lock_guard<std::mutex> lock(db_mutex);
        if(wallets[PRIMARY_ADDRESS]<amount) return "{\"error\":\"Insufficient funds\"}";
        wallets[PRIMARY_ADDRESS]-=amount; wallets[to]+=amount;
        Transaction tx{PRIMARY_ADDRESS,to,"tx"+std::to_string(txCounter++),amount};
        blockchain[blockHeight].txs.push_back(tx);
        saveState();
        return tx.txid;
    }

    std::string getWalletInfo() {
        std::lock_guard<std::mutex> lock(db_mutex);
        json j;
        for(auto &[addr,bal]:wallets) j["addresses"][addr]=bal;
        j["txcount"]=txCounter;
        return j.dump();
    }

    std::string getNewAddress() {
        std::lock_guard<std::mutex> lock(db_mutex);
        static std::mt19937_64 rng(std::random_device{}());
        static std::uniform_int_distribution<int> dist(0,15);
        std::string addr="0x"; for(int i=0;i<40;i++) addr+="0123456789ABCDEF"[dist(rng)];
        wallets[addr]=0; saveState(); return addr;
    }

    void mineBlock() {
        std::lock_guard<std::mutex> lock(db_mutex);
        blockHeight++;
        Block b{blockHeight,"000000block"+std::to_string(blockHeight),{}};
        blockchain[blockHeight]=b;
        wallets[PRIMARY_ADDRESS]+=miningReward;
        saveState();
        std::cout<<"[*] New block mined. Height: "<<blockHeight<<std::endl;
    }

private:
    int blockHeight=1,txCounter=0,miningReward=50;
    std::map<int,Block> blockchain;
    std::map<std::string,int> wallets;

    void saveState() {
        json jchain;
        for(auto &[h,b]:blockchain) {
            json jb; jb["hash"]=b.hash; jb["height"]=b.height; jb["transactions"]=json::array();
            for(auto &tx:b.txs) jb["transactions"].push_back({{"from",tx.from},{"to",tx.to},{"amount",tx.amount},{"txid",tx.txid}});
            jchain[std::to_string(h)]=jb;
        }
        std::ofstream(BLOCKCHAIN_FILE)<<jchain.dump(4);
        json jw; for(auto &[addr,bal]:wallets) jw[addr]=bal;
        std::ofstream(WALLETS_FILE)<<jw.dump(4);
    }

    void loadState() {
        std::ifstream ifs(BLOCKCHAIN_FILE); if(ifs.is_open()) {
            json j; ifs>>j; for(auto &[k,v]:j.items()){Block b; b.height=v["height"]; b.hash=v["hash"];
                for(auto &txj:v["transactions"]){Transaction tx; tx.from=txj["from"]; tx.to=txj["to"]; tx.amount=txj["amount"]; tx.txid=txj["txid"]; b.txs.push_back(tx);}
                blockchain[b.height]=b;
            } blockHeight=blockchain.rbegin()->first; ifs.close();
        } else { blockchain[1]={1,"000000genesis",{} }; blockHeight=1; }
        std::ifstream wifs(WALLETS_FILE); if(wifs.is_open()){json jw; wifs>>jw; for(auto &[addr,bal]:jw.items()) wallets[addr]=bal; wifs.close();}
        if(wallets.find(PRIMARY_ADDRESS)==wallets.end()) wallets[PRIMARY_ADDRESS]=1000000;
    }
};

StateDBImpl db;

void signalHandler(int signum){std::cout<<"\n[!] Caught signal "<<signum<<", shutting down SpiralCoin...\n"; running=false;}

void setupRPCServer() {
    httplib::Server svr;
    svr.Post("/rpc",[](const httplib::Request &req, httplib::Response &res){
        try{
            auto jreq=json::parse(req.body); json jres; jres["id"]=jreq["id"];
            std::string method=jreq["method"].get<std::string>();
            if(method=="getbalance"){std::string addr=jreq["params"].empty()?PRIMARY_ADDRESS:jreq["params"][0].get<std::string>(); jres["result"]=db.getBalance(addr);}
            else if(method=="getwalletinfo") jres["result"]=json::parse(db.getWalletInfo());
            else if(method=="sendtoaddress"){std::string to=jreq["params"][0].get<std::string>(); int amount=jreq["params"][1].get<int>(); jres["result"]=db.sendToAddress(to,amount);}
            else if(method=="getnewaddress") jres["result"]=db.getNewAddress();
            else if(method=="getblockcount") jres["result"]=db.getBlockCount();
            else if(method=="getblock"){int h=jreq["params"][0].get<int>(); jres["result"]=json::parse(db.getBlock(h));}
            else if(method=="getinfo") jres["result"]={ {"status","SpiralCoin Node OK"}, {"blocks",db.getBlockCount()}, {"connections",1} };
            else jres["error"]="Unknown method";
            res.set_content(jres.dump(),"application/json");
        } catch(std::exception &e){json jres; jres["error"]=std::string("Exception: ")+e.what(); res.set_content(jres.dump(),"application/json");}
    });
    std::cout<<"[*] RPC server listening on http://127.0.0.1:8545\n";
    svr.listen("0.0.0.0",8545);
}

int main() {
    std::cout<<"[*] SpiralCoin Node Starting..."<<std::endl;
    std::signal(SIGINT,signalHandler); std::signal(SIGTERM,signalHandler);
    system(("mkdir -p "+DATA_DIR).c_str());
    db.commit();
    std::thread rpcThread(setupRPCServer);
    while(running){db.mineBlock(); std::this_thread::sleep_for(std::chrono::seconds(5));}
    std::cout<<"[*] SpiralCoin daemon exited cleanly."<<std::endl;
    rpcThread.detach();
    return 0;
}
