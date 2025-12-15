#include "dqve_calculator.h"
#include <algorithm>
#include <numeric>
#include <iostream>
#include <cmath>

DQVECalculator::DQVECalculator()
    : rng(std::random_device{}()),
      normalDist(0.0, 1.0) {
}

DQVECalculator::DQVEResult DQVECalculator::calculateDQVE(
    const std::vector<MarketData>& historicalData,
    const MarketData& currentData) {

    DQVEResult result;
    result.timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();

    // Calculate individual components
    double fundamentalValue = calculateFundamentalValue(currentData);
    double technicalMomentum = calculateTechnicalMomentum(historicalData);
    double sentimentScore = calculateSentimentScore(historicalData);
    double networkHealth = calculateNetworkHealthFactor();

    // Apply AI-driven adjustments
    double aiPrediction = applyNeuralNetworkPrediction(historicalData);
    double marketEfficiency = assessMarketEfficiency(historicalData);

    // Weighted calculation with AI enhancement
    result.valuation = (fundamentalValue * FUNDAMENTAL_WEIGHT +
                       technicalMomentum * TECHNICAL_WEIGHT +
                       sentimentScore * SENTIMENT_WEIGHT +
                       networkHealth * NETWORK_WEIGHT) * (1 + aiPrediction * 0.1);

    // Calculate confidence based on data quality and market conditions
    result.confidence = calculateConfidenceScore(historicalData, currentData, marketEfficiency);
    result.trendStrength = calculateTrendStrength(historicalData);
    result.momentum = computeMomentumIndicator(historicalData);

    // Generate recommendation
    result.recommendation = generateRecommendation(result.valuation, result.confidence,
                                                 result.trendStrength, result.momentum);

    // Store factor contributions
    result.factors["fundamental"] = fundamentalValue;
    result.factors["technical"] = technicalMomentum;
    result.factors["sentiment"] = sentimentScore;
    result.factors["network"] = networkHealth;
    result.factors["ai_prediction"] = aiPrediction;
    result.factors["market_efficiency"] = marketEfficiency;

    return result;
}

double DQVECalculator::calculateFundamentalValue(const MarketData& data) {
    // Advanced fundamental analysis
    double liquidityScore = 1.0 / (1.0 + std::exp(-data.liquidity / 1000000.0)); // Sigmoid normalization
    double volatilityPenalty = 1.0 - (data.volatility / 100.0); // Penalize high volatility

    // Market cap valuation with network effects
    double networkMultiplier = 1.0 + std::log10(data.marketCap / 1000000.0) * 0.1;

    return data.price * liquidityScore * volatilityPenalty * networkMultiplier;
}

double DQVECalculator::calculateTechnicalMomentum(const std::vector<MarketData>& data) {
    if (data.size() < 20) return data.back().price;

    // Multi-timeframe momentum analysis
    double shortTermMA = calculateMovingAverage(extractPrices(data), 5);
    double mediumTermMA = calculateMovingAverage(extractPrices(data), 20);
    double longTermMA = calculateMovingAverage(extractPrices(data), 50);

    // RSI calculation
    double rsi = calculateRSI(extractPrices(data), 14);

    // MACD calculation
    auto macd = calculateMACD(extractPrices(data));

    // Combine indicators with weights
    double maScore = (shortTermMA > mediumTermMA ? 1.0 : -1.0) * 0.4 +
                    (mediumTermMA > longTermMA ? 1.0 : -1.0) * 0.3;

    double rsiScore = (rsi - 50) / 50.0; // Normalize RSI around 50

    return (maScore * 0.5 + rsiScore * 0.3 + macd.first * 0.2) * data.back().price + data.back().price;
}

double DQVECalculator::calculateSentimentScore(const std::vector<MarketData>& data) {
    if (data.size() < 10) return 0.5;

    // Volume analysis for sentiment
    auto volumes = extractVolumes(data);
    double avgVolume = std::accumulate(volumes.begin(), volumes.end(), 0.0) / volumes.size();
    double currentVolume = data.back().volume;

    // Price-volume correlation
    double volumeSentiment = currentVolume > avgVolume * 1.2 ? 0.8 :
                           currentVolume < avgVolume * 0.8 ? 0.2 : 0.5;

    // Volatility sentiment (lower volatility = more stable = positive sentiment)
    double volatilitySentiment = 1.0 - (data.back().volatility / 100.0);

    return (volumeSentiment * 0.6 + volatilitySentiment * 0.4);
}

double DQVECalculator::calculateNetworkHealthFactor() {
    // This would integrate with actual network metrics
    // For now, return a baseline value
    return 0.75; // 75% network health
}

double DQVECalculator::applyNeuralNetworkPrediction(const std::vector<MarketData>& data) {
    if (data.size() < 30) return 0.0;

    // Simplified neural network prediction simulation
    // In a real implementation, this would use trained ML models

    auto prices = extractPrices(data);
    double trend = calculateTrendStrength(data);
    double momentum = computeMomentumIndicator(data);
    double volatility = calculateStandardDeviation(prices);

    // Neural network approximation using sigmoid and polynomial features
    double input = trend * 0.4 + momentum * 0.4 + (1.0 - volatility) * 0.2;
    double prediction = 1.0 / (1.0 + std::exp(-input * 2.0)); // Sigmoid activation

    return (prediction - 0.5) * 2.0; // Normalize to [-1, 1]
}

double DQVECalculator::calculateFractalDimension(const std::vector<double>& prices) {
    // Simplified fractal dimension calculation using variance
    if (prices.size() < 10) return 1.5;

    double totalVariance = 0.0;
    for (size_t i = 1; i < prices.size(); ++i) {
        totalVariance += std::pow(std::log(prices[i] / prices[i-1]), 2);
    }
    totalVariance /= (prices.size() - 1);

    // Higher variance suggests more complex (higher dimensional) behavior
    return 1.5 + totalVariance * 0.5;
}

double DQVECalculator::assessMarketEfficiency(const std::vector<MarketData>& data) {
    if (data.size() < 20) return 0.5;

    auto prices = extractPrices(data);
    auto volumes = extractVolumes(data);

    // Calculate price-volume correlation as efficiency measure
    double correlation = calculateCorrelation(prices, volumes);

    // Efficient markets have moderate correlation
    double efficiency = 1.0 - std::abs(correlation - 0.3);

    return std::max(0.0, std::min(1.0, efficiency));
}

double DQVECalculator::predictPriceDirection(const std::vector<MarketData>& data) {
    if (data.size() < 10) return 0.0;

    double shortTermTrend = calculateTrendStrength(data);
    double momentum = computeMomentumIndicator(data);

    // Combine signals for direction prediction
    return (shortTermTrend + momentum) / 2.0;
}

double DQVECalculator::calculateMarketSentiment(const std::vector<MarketData>& data) {
    return calculateSentimentScore(data);
}

double DQVECalculator::calculateVolatilityAdjustedReturn(const std::vector<MarketData>& data) {
    if (data.size() < 2) return 0.0;

    auto prices = extractPrices(data);
    std::vector<double> returns;

    for (size_t i = 1; i < prices.size(); ++i) {
        returns.push_back(std::log(prices[i] / prices[i-1]));
    }

    double avgReturn = std::accumulate(returns.begin(), returns.end(), 0.0) / returns.size();
    double volatility = calculateStandardDeviation(returns);

    // Sharpe ratio approximation
    return volatility > 0 ? avgReturn / volatility : 0.0;
}

double DQVECalculator::assessLiquidityRisk(const MarketData& data) {
    // Liquidity risk assessment based on volume and market cap
    double volumeToCapRatio = data.volume / data.marketCap;

    // Higher ratio = lower risk
    return std::min(1.0, volumeToCapRatio * 100.0);
}

double DQVECalculator::computeMomentumIndicator(const std::vector<MarketData>& data) {
    if (data.size() < 14) return 0.0;

    auto prices = extractPrices(data);
    size_t n = prices.size();

    // ROC (Rate of Change) calculation
    double roc = (prices[n-1] - prices[n-14]) / prices[n-14];

    // Momentum with smoothing
    double momentum = 0.0;
    for (size_t i = n - 10; i < n; ++i) {
        momentum += (prices[i] - prices[i-1]) / prices[i-1];
    }
    momentum /= 10.0;

    return (roc + momentum) / 2.0;
}

// Private helper methods
double DQVECalculator::calculateConfidenceScore(const std::vector<MarketData>& historical,
                                               const MarketData& current,
                                               double efficiency) {
    double dataQuality = std::min(1.0, historical.size() / 100.0);
    double liquidityConfidence = assessLiquidityRisk(current);
    double efficiencyConfidence = efficiency;

    return (dataQuality * 0.4 + liquidityConfidence * 0.3 + efficiencyConfidence * 0.3);
}

double DQVECalculator::calculateTrendStrength(const std::vector<MarketData>& data) {
    if (data.size() < 20) return 0.0;

    auto prices = extractPrices(data);

    // Linear regression slope as trend strength
    double n = prices.size();
    double sumX = n * (n - 1) / 2.0;
    double sumY = std::accumulate(prices.begin(), prices.end(), 0.0);
    double sumXY = 0.0;
    double sumXX = 0.0;

    for (size_t i = 0; i < n; ++i) {
        sumXY += i * prices[i];
        sumXX += i * i;
    }

    double slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    double intercept = (sumY - slope * sumX) / n;

    // Normalize slope by average price
    double avgPrice = sumY / n;
    return slope / avgPrice;
}

std::string DQVECalculator::generateRecommendation(double valuation, double confidence,
                                                 double trendStrength, double momentum) {
    if (confidence < 0.4) return "INSUFFICIENT_DATA";

    double score = (valuation * 0.4 + trendStrength * 0.3 + momentum * 0.3);

    if (score > 0.2 && confidence > CONFIDENCE_THRESHOLD_HIGH) return "STRONG_BUY";
    if (score > 0.1 && confidence > CONFIDENCE_THRESHOLD_MEDIUM) return "BUY";
    if (score < -0.2 && confidence > CONFIDENCE_THRESHOLD_HIGH) return "STRONG_SELL";
    if (score < -0.1 && confidence > CONFIDENCE_THRESHOLD_MEDIUM) return "SELL";

    return "HOLD";
}

// Statistical utility methods
double DQVECalculator::calculateStandardDeviation(const std::vector<double>& values) {
    if (values.empty()) return 0.0;

    double mean = std::accumulate(values.begin(), values.end(), 0.0) / values.size();
    double variance = 0.0;

    for (double value : values) {
        variance += std::pow(value - mean, 2);
    }
    variance /= values.size();

    return std::sqrt(variance);
}

double DQVECalculator::calculateSharpeRatio(const std::vector<double>& returns) {
    if (returns.size() < 2) return 0.0;

    double avgReturn = std::accumulate(returns.begin(), returns.end(), 0.0) / returns.size();
    double stdDev = calculateStandardDeviation(returns);

    // Assuming risk-free rate of 2% annually (0.02/365 for daily)
    double riskFreeRate = 0.02 / 365.0;

    return stdDev > 0 ? (avgReturn - riskFreeRate) / stdDev : 0.0;
}

double DQVECalculator::calculateBetaCoefficient(const std::vector<double>& assetReturns,
                                               const std::vector<double>& marketReturns) {
    if (assetReturns.size() != marketReturns.size() || assetReturns.size() < 2) return 1.0;

    double assetMean = std::accumulate(assetReturns.begin(), assetReturns.end(), 0.0) / assetReturns.size();
    double marketMean = std::accumulate(marketReturns.begin(), marketReturns.end(), 0.0) / marketReturns.size();

    double covariance = 0.0;
    double marketVariance = 0.0;

    for (size_t i = 0; i < assetReturns.size(); ++i) {
        double assetDiff = assetReturns[i] - assetMean;
        double marketDiff = marketReturns[i] - marketMean;

        covariance += assetDiff * marketDiff;
        marketVariance += marketDiff * marketDiff;
    }

    covariance /= assetReturns.size();
    marketVariance /= assetReturns.size();

    return marketVariance > 0 ? covariance / marketVariance : 1.0;
}

double DQVECalculator::calculateCorrelation(const std::vector<double>& x, const std::vector<double>& y) {
    if (x.size() != y.size() || x.size() < 2) return 0.0;

    double sumX = std::accumulate(x.begin(), x.end(), 0.0);
    double sumY = std::accumulate(y.begin(), y.end(), 0.0);
    double sumXY = 0.0;
    double sumXX = 0.0;
    double sumYY = 0.0;

    for (size_t i = 0; i < x.size(); ++i) {
        sumXY += x[i] * y[i];
        sumXX += x[i] * x[i];
        sumYY += y[i] * y[i];
    }

    double n = x.size();
    double numerator = n * sumXY - sumX * sumY;
    double denominator = std::sqrt((n * sumXX - sumX * sumX) * (n * sumYY - sumY * sumY));

    return denominator > 0 ? numerator / denominator : 0.0;
}

// Technical indicator helpers
double DQVECalculator::calculateMovingAverage(const std::vector<double>& data, size_t period) {
    if (data.size() < period) return data.back();

    double sum = 0.0;
    for (size_t i = data.size() - period; i < data.size(); ++i) {
        sum += data[i];
    }
    return sum / period;
}

double DQVECalculator::calculateRSI(const std::vector<double>& prices, size_t period) {
    if (prices.size() < period + 1) return 50.0;

    std::vector<double> gains, losses;

    for (size_t i = 1; i < prices.size(); ++i) {
        double change = prices[i] - prices[i-1];
        if (change > 0) {
            gains.push_back(change);
            losses.push_back(0);
        } else {
            gains.push_back(0);
            losses.push_back(-change);
        }
    }

    // Calculate initial averages
    double avgGain = std::accumulate(gains.end() - period, gains.end(), 0.0) / period;
    double avgLoss = std::accumulate(losses.end() - period, losses.end(), 0.0) / period;

    // Smooth the averages
    for (size_t i = period; i < gains.size(); ++i) {
        avgGain = (avgGain * (period - 1) + gains[i]) / period;
        avgLoss = (avgLoss * (period - 1) + losses[i]) / period;
    }

    double rs = avgLoss > 0 ? avgGain / avgLoss : 0.0;
    return 100.0 - (100.0 / (1.0 + rs));
}

std::pair<double, double> DQVECalculator::calculateMACD(const std::vector<double>& prices) {
    if (prices.size() < 26) return {0.0, 0.0};

    double ema12 = calculateEMA(prices, 12);
    double ema26 = calculateEMA(prices, 26);
    double macd = ema12 - ema26;

    // Signal line (9-period EMA of MACD)
    std::vector<double> macdHistory;
    for (size_t i = 25; i < prices.size(); ++i) {
        double ema12_i = calculateEMA(std::vector<double>(prices.begin() + i - 11, prices.begin() + i + 1), 12);
        double ema26_i = calculateEMA(std::vector<double>(prices.begin() + i - 25, prices.begin() + i + 1), 26);
        macdHistory.push_back(ema12_i - ema26_i);
    }

    double signal = calculateEMA(macdHistory, 9);
    return {macd, signal};
}

double DQVECalculator::calculateEMA(const std::vector<double>& data, size_t period) {
    if (data.size() < period) return data.back();

    double multiplier = 2.0 / (period + 1.0);
    double ema = data[0];

    for (size_t i = 1; i < data.size(); ++i) {
        ema = (data[i] * multiplier) + (ema * (1 - multiplier));
    }

    return ema;
}

// Utility methods
std::vector<double> DQVECalculator::extractPrices(const std::vector<MarketData>& data) {
    std::vector<double> prices;
    prices.reserve(data.size());
    for (const auto& item : data) {
        prices.push_back(item.price);
    }
    return prices;
}

std::vector<double> DQVECalculator::extractVolumes(const std::vector<MarketData>& data) {
    std::vector<double> volumes;
    volumes.reserve(data.size());
    for (const auto& item : data) {
        volumes.push_back(item.volume);
    }
    return volumes;
}

double DQVECalculator::normalizeValue(double value, double min, double max) {
    if (max == min) return 0.5;
    return (value - min) / (max - min);
}
