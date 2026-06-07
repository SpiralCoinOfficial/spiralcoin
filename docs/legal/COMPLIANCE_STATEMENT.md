# COMPLIANCE STATEMENT

<!-- markdownlint-disable MD012 MD013 MD018 MD022 MD026 MD031 MD032 MD034 MD036 MD040 -->

**SpiralCoin Foundation, LLC**

**Effective Date**: March 20, 2026

---

## EXECUTIVE SUMMARY

SpiralCoin Foundation, LLC ("Company") is committed to operating in compliance with all applicable laws and regulatory requirements. This statement outlines our compliance framework, governance structure, and commitment to legal and ethical conduct.

---

## 1. REGULATORY FRAMEWORK

### 1.1 Jurisdictional Analysis

**Company Incorporation**: Delaware, USA

**Primary Operating Markets**:
- United States (SEC, CFTC, FinCEN jurisdiction)
- European Union (GDPR, MiCA)
- Singapore (MAS oversight)
- Japan (FSA jurisdiction)

### 1.2 Applicable Regulations

| Regulation | Scope | Status |
| --- | --- | --- |
| **FinCEN OFAC** | Sanctions screening | ✓ Implemented |
| **GDPR** | EU data protection | ✓ Compliant |
| **CCPA** | California privacy | ✓ Compliant |
| **KYC/AML Laws** | Identity verification | ✓ MVP implemented |
| **MiCA** (EU) | Crypto asset market regulation | ⏳ Monitoring (applies 2024+) |
| **CFTC Guidance** | Derivatives classification | ✓ Reviewed |
| **SEC Rule 10b-5** | Securities fraud | ✓ Compliant |
| **FINRA SRO Rules** | If exchange license (future) | ⏳ Will comply |

---

## 2. COMPANY GOVERNANCE

### 2.1 Legal Structure

- **Entity**: Limited Liability Company (LLC)
- **State**: Delaware
- **Manager**: Matthew Ian Dreyer
- **EIN**: [To be completed upon filing]

### 2.2 Management & Decision-Making

**Current Decision Authority**:
- **Matthew Ian Dreyer**: Founder, CTO, Manager (sole decision-maker, MVP phase)

**Future Governance** (upon growth):
- Board of Directors (if incorporated as C-Corp later)
- Advisory Council (subject matter experts)
- Community DAO (governance token, if implemented)

### 2.3 Policies & Procedures

| Policy | Status | Details |
| --- | --- | --- |
| **Conflict of Interest** | ✓ Drafted | Founder disclosures documented |
| **Code of Conduct** | ✓ Drafted | Anti-fraud, anti-corruption, ethical standards |
| **Whistleblower** | ⏳ Q2 2026 | Internal reporting mechanism (3rd party provider) |
| **Record Retention** | ✓ Active | 7-year RTO (record retention obligation) |
| **Internal Audit** | ✓ Quarterly | Quarterly compliance reviews |

---

## 3. ANTI-MONEY LAUNDERING (AML) / KNOW YOUR CUSTOMER (KYC)

### 3.1 AML Policy

**Risk Categories**:
- High-risk transactions: >$10,000 SPRC per day
- Medium-risk: $1,000–$10,000 per day
- Standard: <$1,000

**Detection Mechanisms**:
- ✓ OFAC SDN list screening (all users)
- ✓ Transaction pattern analysis (flagging velocity, unusual sources)
- ✓ Country/jurisdiction checks (sanction list verification)
- ⏳ Behavioral analytics (Q2 2026 implementation)

### 3.2 KYC Procedures

**MVP Phase** (Current):
- Email verification only
- Username/password authentication
- Transaction logging

**Enhanced KYC** (Q3 2026):
- Full name and date of birth
- Proof of address (utility bill, bank statement)
- Government-issued ID (passport, driver's license)
- Beneficial ownership declaration (if transaction >$50K)

**Professional KYC** (Q4 2026):
- Third-party integrations: Chainalysis, Coinfirm, Uniswap
- Source of funds declaration
- Enhanced due diligence (EDO) for high-risk users

### 3.3 Transaction Monitoring & Reporting

**Suspicious Activity Report (SAR)**:
- Threshold: Unusual patterns or high-risk jurisdictions
- Reporting: FinCEN within 30 days of detection
- Documentation: Retained for 5 years

**Currency Transaction Reports (CTR)**:
- Threshold: Aggregate transactions >$10,000 in 24 hours (if fiat bridge exists)
- Reporting: FinCEN Form 8300
- Exemptions: Existing customers with documented identities

---

## 4. SANCTIONS COMPLIANCE

### 4.1 OFAC Screening

**Process**:
1. All user registrations screened against SDN (Specially Designated Nationals) list
2. Transaction recipients checked at time of sending
3. Quarterly re-screening of active users

**Automated Screening**:
- OFAC SDN in JSON format (updated weekly)
- Fuzzy name matching with 95%+ accuracy threshold
- Manual review for edge cases

**Blocked Transactions**:
- Automatic transaction reversal
- User account suspension pending review
- SAR filing (if applicable)

### 4.2 Restricted Jurisdictions

**Prohibited Regions**:
- North Korea (OFAC DPRK sanctions)
- Iran (OFAC IFSR sanctions)
- Syria (OFAC SSRS sanctions)
- Cuba (OFAC CCRS sanctions)
- Crimea (Russia-occupied territory, OFAC)

**User Access**: Platform access restricted via IP geolocation + user declaration.

---

## 5. DATA PROTECTION & PRIVACY

### 5.1 GDPR Compliance (EU)

**Data Controller**: SpiralCoin Foundation, LLC

**Legal Basis for Processing**:
- Contractual necessity (account services)
- Legal obligation (AML/KYC/sanctions)
- Legitimate interest (fraud prevention)
- Consent (marketing communications, opt-in)

**Data Rights Honored**:
- ✓ Right to access
- ✓ Right to rectification
- ✓ Right to erasure ("right to be forgotten")
- ✓ Right to restrict processing
- ✓ Right to data portability
- ✓ Right to object

**Data Processing Agreements**: All vendors sign DPAs ensuring GDPR compliance.

### 5.2 CCPA Compliance (California)

**California Consumer Rights**:
- ✓ Right to know (request data)
- ✓ Right to delete (request erasure)
- ✓ Right to opt-out (analytics, profiling)
- ✓ Right to non-discrimination (no penalties for exercising rights)

**Opt-Out Mechanism**: Account settings → Disable analytics & marketing.

### 5.3 Data Retention

| Data Type | Retention Period | Reason |
| --- | --- | --- |
| Account info | Until deletion + 90 days | Operational necessity |
| Transaction logs | 7 years | FinCEN regulatory requirement |
| KYC documents | 5 years after closure | AML/KYC requirement |
| Support records | 3 years | Dispute resolution |
| IP logs | 12 months | Security incident investigation |

---

## 6. MARKET CONDUCT & TRADING RULES

### 6.1 Prohibited Activities

**The following are strictly prohibited**:

1. **Market Manipulation**: Pump-and-dump, wash trading, spoofing, layering
2. **Insider Trading**: Trading on material non-public information
3. **Front-Running**: Placing orders before customer orders filled
4. **Best Execution**: Routing orders to maximize user benefit
5. **Fraud**: Misrepresentation, false statements, account takeover
6. **Money Laundering**: Structuring transactions (<$10K) to evade AML thresholds

**Enforcement**:
- Automatic detection algorithms
- Manual review by compliance team
- Account suspension and potential legal referral

### 6.2 Trading Halts & Volatility Limits

**Circuit Breaker Rules** (if implemented):
- Halt trading if price moves >20% in 1 minute
- Duration: 5-minute timeout before resumption
- Goal: Prevent panic selling or flash crashes

**Maker-Taker Fees**:
- Maker (add liquidity): 0.05%
- Taker (remove liquidity): 0.10%
- Fee structure subject to governance changes

---

## 7. CYBERSECURITY & DATA SECURITY

### 7.1 Security Standards

**Infrastructure**:
- ✓ TLS 1.3 encryption for all data in transit
- ✓ AES-256 encryption for sensitive data at rest
- ✓ bcryptjs password hashing (10+ salt rounds)
- ✓ Hardware security modules (HSM) for crypto keys (planned)
- ✓ DDoS protection via Cloudflare
- ✓ Web Application Firewall (WAF)

**Access Controls**:
- ✓ Role-based access control (RBAC)
- ✓ Multi-factor authentication (MFA) available
- ✓ Principle of least privilege
- ✓ Audit logging for all access

### 7.2 Vulnerability Management

**Processes**:
- ✓ Regular security audits (quarterly internal, annual external)
- ✓ Penetration testing (annual)
- ✓ Dependency scanning (continuous via npm audit)
- ✓ Code review (peer review + static analysis)

**Bug Bounty**:
- Launch Q2 2026
- Platform: HackerOne or Bugcrowd
- Scope: Website, APIs, smart contracts
- Reward: $500–$50,000 depending on severity

---

## 8. CUSTOMER FUND PROTECTION

### 8.1 Non-Custodial Model

**SpiralCoin is a non-custodial platform**:
- Users maintain private keys (not held by Company)
- Company does NOT hold customer funds
- Blockchain is the single source of truth
- No insurance required (no custodial risk)

### 8.2 Wallet Security Best Practices

**Company Recommendations**:
- Use hardware wallets (Ledger, Trezor)
- Never share private keys
- Back up seed phrases offline
- Use strong passwords (16+ characters, 2FA)
- Verify addresses before sending transactions

**Terms**: Company is NOT liable for lost keys or unauthorized account access; users assume full responsibility.

---

## 9. DISCLOSURE & TRANSPARENCY

### 9.1 Public Reporting

**Annual Compliance Report**:
- Published Q1 each year
- Covers AML/KYC activities, transactions, sanctions hits
- Format: Publicly available on website (aggregated, no PII)

**Transaction Data**:
- Encrypted blockchain ledger (publicly verifiable)
- Market data (price, volume, order book) public via API
- Individual transaction details private (GDPR compliance)

### 9.2 Risk Disclosures

See [RISK_DISCLOSURES.md](RISK_DISCLOSURES.md) for complete list:
- Technology risks (consensus bugs, smart contract exploits)
- Market risks (volatility, liquidity, price manipulation)
- Regulatory risks (changing laws, jurisdictional restrictions)
- Operational risks (team availability, infrastructure failures)

---

## 10. REGULATORY ROADMAP

### Phase 1: MVP Compliance (March 2026)
- ✓ Email verification
- ✓ OFAC screening
- ✓ Terms of Service & Privacy Policy
- ✓ Security audit

### Phase 2: Enhanced KYC (Q2–Q3 2026)
- Full name/DOB collection
- Proof of address verification
- ID verification (government-issued)
- Source of funds declaration

### Phase 3: Professional Compliance (Q4 2026)
- Third-party KYC/AML vendor integration
- Enhanced due diligence for high-risk users
- SAR/CTR reporting automation
- SOC 2 Type II certification

### Phase 4: Institutional Grade (2027)
- Money Services Business (MSB) licensing (if required)
- Crypto asset exchange license applications
- Qualified Custodian partnership (for future custodial services)
- Insurance coverage (if applicable)

---

## 11. INCIDENT RESPONSE & DISCLOSURES

### 11.1 Security Incident Response Plan

**Activation**:
1. Detect incident (automated alerts + manual monitoring)
2. Contain threat (isolate affected systems)
3. Notify users (within 72 hours of confirmed breach)
4. Remediate vulnerability
5. Post-mortem review

**User Notification**:
- Email to affected users
- Public blog post (aggregated info, no PII)
- Regulatory notifications (if legally required)

### 11.2 Material Change Disclosure

**Events Triggering Disclosure**:
- Major security vulnerabilities
- Regulatory enforcement actions
- Change of control or key personnel
- Financial distress
- Network outages or consensus issues

**Disclosure Method**: Blog post, email notification, regulatory filing.

---

## 12. LEGAL RESOURCES & CONTACTS

### 12.1 Legal & Compliance Contacts

| Function | Contact | Email |
| --- | --- | --- |
| **General Counsel** | TBD | legal@spiralcoin.net |
| **Compliance Officer** | TBD | compliance@spiralcoin.net |
| **Security** | Matthew Dreyer | security@spiralcoin.net |
| **Support** | Support Team | support@spiralcoin.net |

### 12.2 Legal Counsel

**Recommended**: Engage cryptocurrency-experienced law firm for:
- LLC compliance & filings (Delaware)
- Securities law analysis (is SPRC a security?)
- FinCEN AML/KYC guidance
- State MSB licensing (if pursuing)

**Firms to Consider**:
- Consensys Diligence
- Blockchain Association (advocacy group)
- Law offices specializing in digital assets

---

## 13. CERTIFICATION & ATTESTATION

**I, Matthew Ian Dreyer, Founder and Manager of SpiralCoin Foundation, LLC, hereby certify:**

1. ✓ SpiralCoin operates in good faith and with the intention to comply with all applicable laws.
2. ✓ Fraud, market manipulation, and illegal activities are prohibited and subject to enforcement.
3. ✓ User data is protected in accordance with GDPR, CCPA, and industry standards.
4. ✓ OFAC sanctions screening is implemented and enforced.
5. ✓ AML/KYC procedures are in place and continuously improved.
6. ✓ This Compliance Statement reflects our current practices and commitment to legal conduct.

**Signature**: _________________________ (to be executed)

**Date**: March 20, 2026

---

## APPENDIX A: REGULATIONS SUMMARY

- **FinCEN**: Financial Crimes Enforcement Network (US Treasury)
  - AML/KYC enforcement
  - SAR/CTR reporting obligations

- **SEC**: Securities and Exchange Commission
  - Determines if tokens are securities (Howey Test)
  - Registration requirements for exchanges/brokers

- **CFTC**: Commodity Futures Trading Commission
  - Determines if tokens are commodities
  - Derivatives trading oversight

- **GDPR**: General Data Protection Regulation (EU)
  - Data protection and privacy rights
  - DPA requirements with vendors

- **MiCA**: Markets in Crypto-Assets Regulation (EU)
  - Licensing requirements for exchanges and custodians
  - Stablecoin requirements

---

## APPENDIX B: COMPLIANCE CALENDAR

| Date | Event | Responsible Party |
| --- | --- | --- |
| Q2 2026 | Full KYC system live | Product Team |
| Q2 2026 | Bug bounty program launch | Security Team |
| Q3 2026 | Annual compliance report | Compliance Officer |
| Q3 2026 | SOC 2 Type II audit | External auditor |
| Q3 2026 | Smart contract audit | External auditor |
| Q4 2026 | First complete audit cycle | Compliance Officer |

---

**VERSION**: 1.0
**EFFECTIVE**: March 20, 2026
**LAST REVIEWED**: March 20, 2026
**NEXT REVIEW**: September 2026

