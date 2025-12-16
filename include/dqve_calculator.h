#pragma once
#include <vector>
#include <string>
#include <map>
#include <cmath>
#include <chrono>
#include <random>

class DQVECalculator {
public:
    struct MarketData {
        double price;
        double volume;
        double marketCap;
        double volatility;
        double liquidity;
        long long timestamp;
    };

    struct DQVEResult {
        double valuation;
        double confidence;
        double trendStrength;
        double momentum;
        std::string recommendation;
        std::map<std::string, double> factors;
        long long timestamp;
    };

    DQVECalculator();

    // Main DQVE calculation method
    DQVEResult calculateDQVE(const std::vector<MarketData>& historicalData,
                           const MarketData& currentData);

    // AI-driven prediction methods
    double predictPriceDirection(const std::vector<MarketData>& data);
    double calculateMarketSentiment(const std::vector<MarketData>& data);

    // Advanced analytics
    double calculateVolatilityAdjustedReturn(const std::vector<MarketData>& data);
    double assessLiquidityRisk(const MarketData& data);
    double computeMomentumIndicator(const std::vector<MarketData>& data);

private:
    // Core DQVE components
    double calculateFundamentalValue(const MarketData& data);
    double calculateTechnicalMomentum(const std::vector<MarketData>& data);
    double calculateSentimentScore(const std::vector<MarketData>& data);
    double calculateNetworkHealthFactor();

    // AI/ML components
    double applyNeuralNetworkPrediction(const std::vector<MarketData>& data);
    double calculateFractalDimension(const std::vector<double>& prices);
    double assessMarketEfficiency(const std::vector<MarketData>& data);

    // Statistical methods
    double calculateStandardDeviation(const std::vector<double>& values);
    double calculateSharpeRatio(const std::vector<double>& returns);
    double calculateBetaCoefficient(const std::vector<double>& assetReturns,
                                  const std::vector<double>& marketReturns);
    double calculateCorrelation(const std::vector<double>& x, const std::vector<double>& y);

    // Technical indicators and confidence
    double calculateConfidenceScore(const std::vector<MarketData>& historical,
                                   const MarketData& current,
                                   double efficiency);
    double calculateTrendStrength(const std::vector<MarketData>& data);
    std::string generateRecommendation(double valuation, double confidence,
                                      double trendStrength, double momentum);

    // Technical indicator helpers
    double calculateMovingAverage(const std::vector<double>& data, size_t period);
    double calculateRSI(const std::vector<double>& prices, size_t period);
    std::pair<double, double> calculateMACD(const std::vector<double>& prices);
    double calculateEMA(const std::vector<double>& data, size_t period);

    // Utility methods
    std::vector<double> extractPrices(const std::vector<MarketData>& data);
    std::vector<double> extractVolumes(const std::vector<MarketData>& data);
    double normalizeValue(double value, double min, double max);

    // Random number generator for AI simulations
    std::mt19937_64 rng;
    std::normal_distribution<double> normalDist;

    // DQVE constants (can be fine-tuned)
    static constexpr double FUNDAMENTAL_WEIGHT = 0.35;
    static constexpr double TECHNICAL_WEIGHT = 0.30;
    static constexpr double SENTIMENT_WEIGHT = 0.20;
    static constexpr double NETWORK_WEIGHT = 0.15;

    static constexpr double CONFIDENCE_THRESHOLD_HIGH = 0.8;
    static constexpr double CONFIDENCE_THRESHOLD_MEDIUM = 0.6;
};
