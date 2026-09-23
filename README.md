# Welfare Saathi (വെൽഫെയർ സാഥി)
### Welfare Entitlement Assistant for Plantation & Fishing Families
**Track 3:** Public Welfare and Access | **Challenge ID:** PS-07  
**Hackathon:** ANAVANDI Grand Finale 2026  
**Platforms Supported:** 📱 Android Mobile | 🌐 Web Application | 💻 Windows Desktop  
*(Linux and macOS targets deprecated and stripped for focused deployment)*

---

## 📌 Project Overview
Eligible traditional fishing and plantation households often miss out on vital welfare entitlements due to complex official terminology, lack of awareness of required documents, and confusing application routes.

**Welfare Saathi** is an accessible, bilingual (Malayalam & English), privacy-first welfare screening assistant designed specifically for:
1. **Coastal Fishing Communities:** Traditional fishermen, allied fish workers, fisherwomen SHG members.
2. **Hill Plantation Families:** Tea, coffee, rubber, and cardamom plantation laborers living in layams.

---

## 🌟 Key Features & Device-Adaptive Capabilities

### 1. 📱 Device-Adaptive PDF Export Outlay
- **Android Mobile Experience:**
  - **Native Android Sharesheet:** Uses `Printing.sharePdf` to open the native Android share dialog, enabling 1-tap sharing to **WhatsApp** (to send directly to Ward Members, Kudumbashree ADS, or Akshaya operators), Google Drive, or Gmail.
  - **Android Print Spooler:** Integrates with `Printing.layoutPdf` to connect directly to Wi-Fi/Bluetooth thermal printers in village kiosks.
- **Web & Windows Desktop Experience:**
  - Triggers a direct browser file download dialog saving `welfare_saathi_screening_report.pdf` locally with zero pop-up blocking issues.

### 2. 🎴 Visual Kerala Ration Card Color Selector
- **Android Mobile:**
  - Touch-first horizontal swipe carousel (`PageView`) showcasing realistic Kerala ration card designs:
    - 🟡 **Yellow (AAY):** Antyodaya Anna Yojana (Most Vulnerable)
    - 🔴 **Pink (PHH):** Priority Household (BPL)
    - 🔵 **Blue (NPHH):** Non-Priority Subsidy
    - ⚪ **White (Non-Priority):** Non-Priority Non-Subsidy
  - Features viewport peeking, smooth swipe physics, and animated indicator dots.
- **Web & Desktop:**
  - Responsive 4-box color card grid allowing instant 1-click selection with bold color borders and bilingual category badges.

### 3. 📜 Pre-Filled Malayalam Self-Declaration (Affidavit) Generator
- Generates an official 1-page Malayalam legal declaration (**സത്യപ്രസ്താവന**) compliant with Kerala Revenue and Welfare Board guidelines.
- Pre-fills applicant's occupation, district, monthly income, ration card category, welfare board registration status, and matched schemes.
- Formatted with applicant signature blocks, village officer counter-signature seal spots, and statutory safety disclaimers for direct submission.

### 4. 🏆 USP 1: Akshaya Fast-Track QR Packet & Operator Terminal
- **Offline Zero-PII QR Code:** Encodes applicant screening parameters and matched scheme IDs into a compact Base64 payload (`WS:...`). Strictly excludes sensitive PII (Aadhaar, name, phone, address).
- **Dedicated Akshaya Operator Terminal (`/operator`):**
  - Instant intake screen for Akshaya centre operators.
  - Displays verified document checklists for all matched schemes.
  - Direct 1-tap links to official departmental portals (e.g. *kfwfb.kerala.gov.in*, *edistrict.kerala.gov.in*, *matsyafed.in*).
  - Explicit Akshaya service fee caps (e.g. ₹25–₹50) to protect vulnerable workers from overcharging.

### 5. 💰 USP 2: Entitlement Leakage Audit & Value Calculator
- **Total First-Year Entitlement Calculator:** Instantly calculates the aggregate annual monetary value of all potentially eligible schemes (e.g., ₹19,200/year pension + ₹4,500 lean relief + ₹4,00,000 housing grant).
- **Retroactive Entitlement Leakage Audit:** For households not registered with the Welfare Board, the auditor computes retroactive lost benefits over the past 3 years (e.g., ₹86,100 missed) with urgent guidance to register immediately.

---

## 🛡️ Core Competition Compliance & Principles

1. **Zero Hallucination / Pure Deterministic Engine:**
   - Eligibility is computed by a **100% deterministic rule engine** (`EligibilityEngine`).
   - **No AI / LLM is involved in eligibility decisions.**
2. **Strict Safety Wording:**
   - The application **never** states *"You are eligible"*.
   - It strictly states **"Potentially Eligible"** (ലഭിക്കാൻ സാധ്യതയുണ്ട്).
   - Mandatory official disclaimer is permanently displayed on every screen:
     > *"Results are potential eligibility indications based on the supplied scheme rules. Final eligibility is determined by the relevant authority."*
3. **Incomplete Information Handling:**
   - If a required field is missing or skipped, the engine **never assumes an answer**.
   - It classifies the scheme as **"More Information Needed"** and explicitly highlights the missing question.
4. **Privacy & Data Minimization:**
   - In-memory evaluation only. No database storage, no tracking cookies.
   - **Zero collection** of Aadhaar numbers, personal phone numbers, names, or street addresses.
5. **Full Recalculation Support:**
   - Users can review and edit answers individually and trigger instant re-screening.

---

## 🏗️ Architecture & Data Flow

```
                      [ User ]
                         │
                         ▼
        ┌──────────────────────────────────┐
        │  Malayalam / English UI (Flutter)│
        │  - Adaptive Ration Card Swiper   │
        │  - Mobile Overflow Safeguards    │
        └────────────────┬─────────────────┘
                         │
                         ▼
        ┌──────────────────────────────────┐
        │     Household Screening Form     │
        └────────────────┬─────────────────┘
                         │
                         ▼
        ┌──────────────────────────────────┐
        │    Validated Household Profile   │
        └────────────────┬─────────────────┘
                         │
                         ▼
        ┌──────────────────────────────────┐
        │  Deterministic EligibilityEngine │
        │  - Rule by rule evaluation       │
        │  - Missing information detector  │
        └────────────────┬─────────────────┘
                         │
                         ▼
        ┌──────────────────────────────────┐
        │        Screening Results         │
        │  ├── Potentially Eligible        │
        │  ├── More Information Needed     │
        │  └── Not Matched                 │
        └────────────────┬─────────────────┘
                         │
        ┌────────────────┴──────────────────────────────┐
        │                                               │
        ▼                                               ▼
┌──────────────────────────────────┐   ┌──────────────────────────────────┐
│   Value & Leakage Calculations   │   │   Device-Adaptive Action Suite   │
│   ├── First-Year Total Value     │   │   ├── Android Native Sharesheet  │
│   └── 3-Year Leakage Audit       │   │   ├── Malayalam Affidavit PDF    │
└──────────────────────────────────┘   │   └── Fast-Track Akshaya QR      │
                                       └──────────────────────────────────┘
```

---

## 📋 16 Verified Schemes Covered

| ID | Scheme Name (English / Malayalam) | Department / Board | Target Group |
|---|---|---|---|
| `SCHEME-01` | Matsyathozhilali Old Age Pension Scheme<br>*(മത്സ്യത്തൊഴിലാളി വാർദ്ധക്യകാല പെൻഷൻ)* | Kerala Fishermen's Welfare Fund Board | Fishing |
| `SCHEME-02` | Fishermen Lean Period & Monsoon Relief<br>*(ട്രോളിംഗ് നിരോധന/മൺസൂൺ ആശ്വാസ ധനസഹായം)* | Department of Fisheries, Kerala | Fishing |
| `SCHEME-03` | Matsya Theeram Coastal Housing Scheme<br>*(മത്സ്യത്തീരം സുരക്ഷിത തീരദേശ ഭവന പദ്ധതി)* | Fisheries & LIFE Mission | Fishing |
| `SCHEME-04` | Matsyakanya Higher Education Scholarship<br>*(മത്സ്യത്തൊഴിലാളി മക്കൾക്കുള്ള ഉന്നതവിദ്യാഭ്യാസ സ്കോളർഷിപ്പ്)* | Kerala Fishermen's Welfare Fund Board | Fishing |
| `SCHEME-05` | Fishermen Group Accident Insurance<br>*(മത്സ്യത്തൊഴിലാളി ഗ്രൂപ്പ് അപകട ഇൻഷുറൻസ്)* | Fisheries / NFDB | Fishing |
| `SCHEME-06` | Plantation Workers Housing Subsidy<br>*(തോട്ടം തൊഴിലാളി ഭവന പുനരുദ്ധാരണ ധനസഹായം)* | Plantation Workers Welfare Fund Board | Plantation |
| `SCHEME-07` | Plantation Workers Children Merit Scholarship<br>*(തോട്ടം തൊഴിലാളി കുട്ടികൾക്കുള്ള മെറിറ്റ് സ്കോളർഷിപ്പ്)* | Plantation Workers Welfare Fund Board | Plantation |
| `SCHEME-08` | Plantation Workers Relief & Medical Aid<br>*(തോട്ടം തൊഴിലാളി ചികിത്സാ ധനസഹായം)* | Plantation Workers Welfare Fund Board | Plantation |
| `SCHEME-09` | Matsyafed Micro-Finance for Fisherwomen<br>*(മത്സ്യഫെഡ് വനിതാ സ്വയംസഹായ സംഘ വായ്പ)* | Matsyafed | Fishing |
| `SCHEME-10` | Widowed & Destitute Plantation Pension<br>*(തോട്ടം തൊഴിലാളി വിധവാ/നിരാലംബ പെൻഷൻ)* | Plantation Workers Welfare Fund Board | Plantation |
| `SCHEME-11` | Fishermen Sea Safety Equipment Subsidy<br>*(മത്സ്യബന്ധന കടൽ സുരക്ഷാ ഉപകരണ സബ്സിഡി)* | Department of Fisheries, Kerala | Fishing |
| `SCHEME-12` | Punargeham Coastal Relocation & Housing<br>*(പുനർഗേഹം സുരക്ഷിത പുനരധിവാസ പദ്ധതി)* | Department of Fisheries, Kerala | Fishing |
| `SCHEME-13` | Fishermen Daughter Marriage Financial Aid<br>*(മത്സ്യത്തൊഴിലാളി പെൺമക്കളുടെ വിവാഹ ധനസഹായം)* | Kerala Fishermen's Welfare Fund Board | Fishing |
| `SCHEME-14` | Fisherwomen Maternity Financial Assistance<br>*(മത്സ്യത്തൊഴിലാളി വനിതാ പ്രസവാനുകൂല്യ പദ്ധതി)* | Kerala Fishermen's Welfare Fund Board | Fishing |
| `SCHEME-15` | Plantation Workers Daughter Marriage Aid<br>*(തോട്ടം തൊഴിലാളി പെൺമക്കളുടെ വിവാഹ ധനസഹായം)* | Plantation Workers Welfare Fund Board | Plantation |
| `SCHEME-16` | Plantation Workers Maternity Benefit Scheme<br>*(തോട്ടം തൊഴിലാളി പ്രസവാനുകൂല്യ ധനസഹായം)* | Plantation Workers Welfare Fund Board | Plantation |

---

## 📖 Dedicated Scheme Directory & Handbook
In addition to step-by-step household eligibility screening, users can browse the **Complete Scheme Handbook (`/directory`)**:
- **Searchable Index:** Instant filter by Malayalam or English keyword, sector (`Fishing`, `Plantation`), or benefit type (`Pensions`, `Housing`, `Education`, `Medical`, `Marriage & Maternity`).
- **Comprehensive Profile for Every Scheme:** Full description, eligibility rule parameters, checklist of required documents, department citations (G.O./Act references), designated Akshaya center routes, and application procedures.
- **Direct Eligibility Check:** One-tap navigation to screen a household specifically against any scheme.

---

## 🏛️ Akshaya Centre Directory Integration
For each verified scheme, the application connects the household with nearest **Akshaya E-Centres** matching their district (e.g. Alappuzha, Ernakulam, Idukki, Wayanad, Kollam, Thiruvananthapuram, Kozhikode) with:
- Akshaya Centre Name & Panchayat
- Physical landmark / location
- Official contact person and verified phone number
- List of supported e-services (Welfare board portal, income certificate, ration card updates)

---

## 🧪 Automated Test Suite (50 Tests Passing)

The project includes an exhaustive test suite across 7 dedicated test files in `test/`:
1. **Authentication & Profile Persistence (`test/auth_profile_test.dart` — 15 Tests):**
   - Unauthenticated startup routing to `LoginScreen` via `AuthGate`.
   - 10-digit mobile number input & `+91` E.164 normalization.
   - OTP verification with test code (`123456`) support.
   - Session restoration on app reopen (bypasses login).
   - Profile loading and field mapping (Age, District, Occupation, Income, Board, Ration Card).
   - Returning user edit-only-changed-fields (e.g. Age 62 → 63).
   - Clearing fields to `null` without fake/artificial defaults.
   - "Start New Screening" clean session without silent copying.
   - Deterministic eligibility recalculation on profile updates.
   - Explicit logout immediately returning to `LoginScreen`.
2. **Deterministic Eligibility Engine (`test/eligibility_engine_test.dart` — 10 Tests):**
   - Verified 16-scheme dataset integrity.
   - Senior fisherman profile (Pension, Relief, Insurance).
   - Non-qualifying household disqualification across all sector schemes.
   - Missing information flags `moreInformationRequired` with exact prompts.
   - Correction & recalculation to `potentiallyEligible`.
   - Exact boundary conditions (age 59 vs 60, income ₹8,333 vs ₹8,334).
   - Strict safety language asserting "Potentially Eligible" (never "You are eligible").
   - Plantation coverage (housing, education scholarships, maternity, marriage aid).
3. **Feature Extensions & Leakage Audit (`test/feature_extensions_test.dart` — 6 Tests):**
   - Entitlement value calculation (monthly, annual, first-year total).
   - Retroactive entitlement leakage audit computation (3-year unclaimed loss).
   - Member tenure bypass for leakage report.
   - Zero-PII QR packet Base64 serialization and deserialization.
   - Corrupt QR packet handling.
   - Malayalam legal affidavit PDF byte generation.
4. **Fresh Screening & Null Preservation (`test/fresh_screening_test.dart` — 6 Tests):**
   - Asserts unselected fields remain strictly `null` (never defaults like age 58 or dilapidated).
5. **Community Safety Alerts (`test/safety_alerts_test.dart` — 7 Tests):**
   - High-seas rough weather warnings, landslide hill advisories, bilingual text, sector/district filtering.
6. **Welfare Screening PDF Export (`test/pdf_export_test.dart` — 4 Tests):**
   - PDF entitlement report generation with official legal disclaimers.
7. **Bilingual UI Smoke & Directory Navigation (`test/widget_test.dart` — 2 Tests):**
   - Full smoke test and 16-scheme handbook index navigation.

```bash
# Run complete test suite (50/50 passing)
flutter test

# Run static analysis (0 issues)
flutter analyze

# Build production web bundle
flutter build web --release
```

# Run static analysis (0 issues)
flutter analyze

# Build production web bundle
flutter build web --release
```

---

## 🚀 Running & Building Welfare Saathi

### Android (Mobile)
```bash
# Run on connected Android device / emulator
flutter run -d android

# Build release APK
flutter build apk --release
```

### Web
```bash
# Run in Chrome
flutter run -d chrome

# Build production web bundle
flutter build web --release
```

### Windows Desktop
```bash
# Run on Windows
flutter run -d windows

# Build Windows executable
flutter build windows --release
```

---

## 🎤 Judge Presentation & Defense Cheat-Sheet

| Question | Explanation to tell Judges |
|---|---|
| **Why Android + Web + Windows?** | Android empowers ground-level field workers (ASHA workers, Kudumbashree ADS, ward volunteers) directly on smartphones. Web and Windows enable kiosk and desktop operation at Akshaya E-Centres and Panchayat offices. |
| **How does device-adaptive PDF export work?** | On Android, it invokes the native Sharesheet for direct WhatsApp sharing to ward members or operators, and the Android Print Spooler. On Web/Windows, it downloads the PDF file directly. |
| **Why the visual Kerala ration card swiper?** | 80%+ of beneficiaries identify their socio-economic status by their physical ration card color (Yellow/Pink/Blue/White) rather than administrative terms like "AAY" or "PHH". A touch-friendly swiper eliminates literacy barriers. |
| **What is the Akshaya Fast-Track QR Packet?** | An offline Base64 QR code encoding applicant criteria and matched scheme IDs. The Akshaya operator scans it to instantly load the checklist, official portal links, and fee limits without re-typing data. Zero PII is stored or transmitted. |
| **What is Entitlement Leakage Audit?** | Unregistered workers often lose thousands in unclaimed benefits. Our engine quantifies the exact financial loss over the past 3 years (e.g. ₹86,100) to create compelling urgency to register with the Welfare Board. |
| **Why is AI not the source of truth?** | Government welfare eligibility is legally binding. LLMs hallucinate rules, thresholds, and income limits. A deterministic engine guarantees 100% auditable, repeatable outcomes. |
| **How is incomplete information handled?** | If a field is `null` (skipped), the engine does not guess. It flags `moreInformationRequired` and specifies the exact question needed. |

---

## 🤖 AI-Use Declaration

As required by the ANAVANDI Grand Finale 2026 regulations:
- **AI Tools Used:** Antigravity AI Coding Assistant (Gemini 3.8 Flash).
- **Purpose of AI Usage:** Accelerated code structuring, generating bilingual JSON terminology dictionaries, compiling test cases, and implementing standard Flutter widgets.
- **Components AI-Assisted:** Boilerplate widget scaffolding, initial dictionary definitions, and test structure formatting.
- **Human Verification & Control:** 100% of the scheme eligibility logic, rule evaluation operators, threshold boundaries, and privacy safeguards were designed, verified, and audited by the human engineer. Zero eligibility decisions are delegated to AI.
