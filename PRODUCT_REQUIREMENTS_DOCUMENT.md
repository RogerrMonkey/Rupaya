# Rupaya - Personal Finance Management App
## Complete Product Requirements Document (PRD)

---

## 📋 Table of Contents
1. [Executive Summary](#executive-summary)
2. [Color Scheme & Brand Identity](#color-scheme--brand-identity)
3. [Typography & Design System](#typography--design-system)
4. [User Flows](#user-flows)
5. [Screen-by-Screen Breakdown](#screen-by-screen-breakdown)
6. [Gamification Elements](#gamification-elements)
7. [Data Models](#data-models)
8. [Multi-Language Support](#multi-language-support)
9. [Icons & Emojis](#icons--emojis)
10. [Animations & Interactions](#animations--interactions)

---

## 🎯 Executive Summary

**Rupaya** is a personal finance management application designed specifically for low-income individuals in India with irregular income sources. The app combines practical money management with gamification elements to make financial tracking engaging and motivational.

**Target Audience:**
- Low-income individuals (daily wage workers, gig economy workers)
- Users with irregular income streams
- People managing multiple small debts
- Hindi, Marathi, and English speakers

**Core Value Proposition:**
- Simple, visual financial tracking
- Gamified debt repayment motivation
- Multi-language support for accessibility
- Voice input for quick data entry
- Offline-first SQLite database

---

## 🎨 Color Scheme & Brand Identity

### Primary Colors

| Color Name | Hex Code | RGB | Usage |
|------------|----------|-----|-------|
| **Primary Green** | `#46EC13` | rgb(70, 236, 19) | Primary actions, positive indicators, success states |
| **Background Gray** | `#F6F8F6` | rgb(246, 248, 246) | App background, neutral space |
| **Error Red** | `#F44336` | rgb(244, 67, 54) | Errors, debts owed, negative balances |
| **Success Green** | `#4CAF50` | rgb(76, 175, 80) | Money received, positive balances |

### Secondary Colors

| Color Name | Hex Code | Usage |
|------------|----------|-------|
| **Food Orange** | `#FF5722` | Food category |
| **Travel Blue** | `#2196F3` | Travel category |
| **Shopping Purple** | `#9C27B0` | Shopping category, motivational cards |
| **Entertainment Orange** | `#FF9800` | Entertainment category |
| **Education Indigo** | `#3F51B5` | Education category |
| **Health Green** | `#4CAF50` | Health category |
| **Misc Gray** | `#607D8B` | Miscellaneous category |
| **Pink** | `#E91E63` | Savings piggy bank |
| **Deep Purple** | `#673AB7` | Motivational gradient |

### Gradient Combinations

**Positive Balance Gradient:**
```css
linear-gradient(135deg, #46EC13 0%, #34D399 100%)
```

**Negative Balance Gradient:**
```css
linear-gradient(135deg, #F44336 0%, #EF5350 100%)
```

**Achievement Gradient:**
```css
linear-gradient(135deg, #46EC13 0%, #2E7D32 100%)
```

**Motivational Gradient:**
```css
linear-gradient(135deg, #9C27B0 0%, #673AB7 100%)
```

---

## 📝 Typography & Design System

### Font Hierarchy

**Headers:**
- Large Title: 22px, Bold, Black
- Section Title: 20px, Bold, Black
- Card Title: 17-18px, Bold, Black
- Subsection: 16px, Bold, Black

**Body Text:**
- Regular: 14-15px, Normal, Black/Gray
- Small: 12-13px, Normal, Gray
- Tiny: 10-11px, Normal, Gray

**Display Numbers:**
- Large Amount: 42-48px, Bold, White/Black
- Medium Amount: 28-38px, Bold, White/Black
- Small Amount: 16-18px, Bold, Color-coded

### Spacing System

- Extra Small: 4px
- Small: 8px
- Medium: 12px
- Large: 16px
- Extra Large: 20px
- XXL: 24px

### Border Radius

- Small: 10-12px
- Medium: 16px
- Large: 20px
- Extra Large: 24px
- Circle: 50%

### Shadows

**Light Shadow:**
```css
box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
```

**Medium Shadow:**
```css
box-shadow: 0 3px 10px rgba(0, 0, 0, 0.05);
```

**Colored Shadow (Balance Card):**
```css
box-shadow: 0 8px 15px rgba(70, 236, 19, 0.25); /* Green */
box-shadow: 0 8px 15px rgba(244, 67, 54, 0.25); /* Red */
```

---

## 🔄 User Flows

### 1. Onboarding Flow

```
┌─────────────────┐
│ Language Select │
│  🌐 Hi/Mr/En   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Onboarding 1   │
│ 💰 Track Money  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Onboarding 2   │
│ 🎯 Set Goals    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Onboarding 3   │
│ 🏆 Achievements │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Registration   │
│ 📝 Name, PIN    │
│ 💵 Income Info  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Home Screen   │
└─────────────────┘
```

### 2. Login Flow

```
┌─────────────────┐
│  Login Screen   │
│  🔐 Enter PIN   │
└────────┬────────┘
         │
    ┌────┴────┐
    │ Verify  │
    └────┬────┘
         │
    ┌────┴─────────┐
    │              │
    ▼              ▼
┌───────┐    ┌──────────┐
│Success│    │ Error ❌ │
└───┬───┘    └──────────┘
    │
    ▼
┌─────────────────┐
│   Home Screen   │
└─────────────────┘
```

### 3. Add Income Flow

```
┌─────────────────┐
│   Home Screen   │
│  Click "Add     │
│   Income" 💰    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Add Income Form │
│ • Amount ₹      │
│ • Source 📋     │
│ • Date 📅       │
│ • Recurring? 🔄 │
│ • Voice Input🎤 │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Save & Return  │
│  Total Money ⬆ │
└─────────────────┘
```

### 4. Add Expense Flow

```
┌─────────────────┐
│   Home Screen   │
│  Click "Add     │
│  Expense" 🛒    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│Add Expense Form │
│ • Amount ₹      │
│ • Category 🏷️   │
│ • Date 📅       │
│ • Note 📝       │
│ • Voice Input🎤 │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Save & Return  │
│  Total Money ⬇ │
└─────────────────┘
```

### 5. Debt Management Flow

```
┌─────────────────┐
│  Add Debt Form  │
│ • Person Name   │
│ • Amount ₹      │
│ • Direction:    │
│   - I Owe 😰    │
│   - Owed to Me😊│
│ • Due Date 📅   │
│ • Description   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Debt List      │
│ • Active Debts  │
│ • Progress Bars │
│ • Pay Button 💳 │
└────────┬────────┘
         │
    ┌────┴────┐
    │  Pay    │
    └────┬────┘
         │
         ▼
┌─────────────────┐
│ Payment Dialog  │
│ Enter Amount ₹  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update Balance  │
│ • Total Money⬇  │
│ • Debt Monster⬇ │
│ • Achievement?🏆│
└─────────────────┘
```

---

## 🎤 Voice Input Feature (AI-Powered Multilingual)

### Overview

Rupaya includes an advanced AI-assisted voice input system that allows users to speak naturally in Hindi, Marathi, or English to automatically record income, expenses, or debts. The system works offline using on-device speech recognition and intelligent NLP parsing.

### Technical Architecture

**Core Technologies:**
- `speech_to_text` ^7.0.0 → Offline speech recognition with language pack support
- `flutter_tts` ^4.0.2 → Text-to-speech feedback
- `permission_handler` ^11.3.1 → Microphone permission management
- `google_mlkit_language_id` ^0.10.0 → Automatic language detection
- Custom NLP parser → Pattern-based transaction extraction

**Supported Languages:**
- Hindi (hi-IN)
- Marathi (mr-IN)
- English (en-IN)

### Voice Input Flow

```
┌──────────────────────┐
│ User taps mic button │
│ (Home/Add screens)   │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Check permissions    │
│ Show consent dialog  │
│ (first time only)    │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Start listening      │
│ Show animated dialog │
│ with pulsing mic     │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ User speaks:         │
│ "Aaj 500 kamaaye"    │
│ "Khana par 200"      │
│ "Raj ko 300 diye"    │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ NLP Parser extracts: │
│ • Type (income/      │
│   expense/debt)      │
│ • Amount (₹500)      │
│ • Category/Person    │
│ • Description        │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Auto-save to SQLite  │
│ OR fill form fields  │
│ Show success + TTS   │
└──────────────────────┘
```

### User Interface Components

#### 1. Floating Mic Button (Home Screen)

**Location:** Bottom-right floating action button

**Design:**
```css
backgroundColor: #46EC13 (green)
size: 56x56px
icon: mic (white, 28px)
elevation: 6px
onTap: Opens voice input dialog
```

**Behavior:**
- Always visible on home screen
- Bounces on tap
- Opens full-screen voice dialog
- Checks permissions before activation

#### 2. Voice Input Dialog

**Layout:**
```
┌──────────────────────────┐
│         [Close ×]         │
│                           │
│    ┌────────────┐        │
│    │   🎤 Mic   │        │
│    │  (Pulsing) │        │
│    └────────────┘        │
│                           │
│  "Listening... Speak now" │
│                           │
│  ┌──────────────────────┐│
│  │ You said:            ││
│  │ "Khana par 200"      ││
│  └──────────────────────┘│
│                           │
│  Example phrases:         │
│  [500 कमाये] [खाना 200]  │
│  [Raj को 300 दिए]       │
└──────────────────────────┘
```

**States:**
- **Listening:** Green pulsing mic, "Listening..." text
- **Processing:** Spinner, "Processing..." text
- **Success:** Checkmark, TTS feedback, auto-close
- **Error:** Red text, "Try Again" button

#### 3. Field-Level Voice Input (Add Screens)

**Add Expense / Add Debt Screens:**
- Small mic icon (🎤) next to amount field
- Tap to start listening
- Fills form fields automatically
- Shows detected values with green highlight

### Natural Language Processing (NLP)

#### Transaction Type Detection

**Income Keywords:**
| Language | Keywords |
|----------|----------|
| English  | earned, income, received, got, salary, payment |
| Hindi    | kamaaye, kamaaya, mila, mile, aaya, aayi, amdani |
| Marathi  | milale, mila, kamavale, utpanna, alapla |

**Expense Keywords:**
| Language | Keywords |
|----------|----------|
| English  | spent, expense, paid, bought, purchase |
| Hindi    | kharch, kharcha, kharche, khareeda, liya, bhara |
| Marathi  | kharch, kharchale, bharale, kharidla, dila |

**Debt (I Owe) Keywords:**
| Language | Keywords |
|----------|----------|
| English  | owe, borrowed, took loan, gave to, lent to |
| Hindi    | diye, diya, udhaar, karza, maine |
| Marathi  | dile, dila, pharaki, karj |

**Debt (Owed to Me) Keywords:**
| Language | Keywords |
|----------|----------|
| English  | owes me, lent, gave loan, borrowed from me |
| Hindi    | mujhe, lena, milna, dena |
| Marathi  | mala, ghene, milane |

#### Amount Extraction

**Number Patterns:**
- Direct digits: `500`, `1000`, `250`
- Hindi words: `paanch sau` → 500, `hazaar` → 1000
- Marathi words: `paachshhe` → 500, `hazaar` → 1000

**Supported Formats:**
```
500 rupaye
paanch sau
teen hazaar
1000 ka
₹500
```

#### Category Detection (Expenses)

| Category | English | Hindi | Marathi |
|----------|---------|-------|---------|
| Food | food, eat, meal | khana, nashta | jevan, khanya |
| Travel | travel, bus, taxi | safar, bus | pravas, bus |
| Bills | bill, electricity, rent | bijli, kiraya | vij, bhaade |
| Shopping | shopping, clothes | kapde, kharida | kapde, vikat |
| Health | medicine, doctor | dawa, hospital | aushadh, doctor |

#### Person Name Extraction (Debts)

**Patterns:**
- `[Name] ko diye` → "I gave to [Name]"
- `[Name] ne mujhe` → "[Name] gave to me"
- Capitalized words in speech
- Context markers: `ko`, `ne`, `to`, `from`, `se`

### Example Voice Commands

#### Income Examples

| Spoken Phrase | Detected Entry |
|---------------|----------------|
| "Aaj 1000 rupaye kamaaye" | Income: ₹1,000 |
| "Maa ne 200 diye" | Income: ₹200 (from Maa) |
| "Earned 500 today" | Income: ₹500 |
| "Salary 15000 mila" | Income: ₹15,000 (Salary) |

#### Expense Examples

| Spoken Phrase | Detected Entry |
|---------------|----------------|
| "Khaane par 300 kharch hue" | Expense: ₹300, Category: Food |
| "Light bill 500 bhara" | Expense: ₹500, Category: Bills |
| "Bus mein 50 rupaye" | Expense: ₹50, Category: Travel |
| "Spent 150 on shopping" | Expense: ₹150, Category: Shopping |

#### Debt Examples

| Spoken Phrase | Detected Entry |
|---------------|----------------|
| "Raj ko 1000 diye" | Debt (I Owe): ₹1,000 to Raj |
| "Priya ne mujhe 500 diye" | Debt (Owed to Me): ₹500 from Priya |
| "Maine Amit ko 300 udhaar diye" | Debt (I Owe): ₹300 to Amit |
| "Sunita owes me 800" | Debt (Owed to Me): ₹800 from Sunita |

### Permission & Privacy

#### First-Time Consent Dialog

**Title:** Voice Input Permission 🎤

**Message:**
"Rupaya uses your microphone to help you add income, expenses, and debts by voice. This makes tracking your finances faster and easier."

**Privacy Points:**
✓ No audio is stored on our servers
✓ Voice data is processed locally
✓ You can disable this anytime in Settings

**Buttons:**
- [Not Now] (decline)
- [Allow] (accept + request OS permission)

#### Permission States

1. **No Consent:** Show consent dialog → Request OS permission
2. **Consent Granted:** Check OS permission
3. **OS Denied:** Show "Open Settings" dialog
4. **Permanently Denied:** Guide to app settings

#### Privacy Storage

- Consent flag: `SharedPreferences` → `voice_input_consent_granted`
- Voice enabled: `SharedPreferences` → `voice_input_enabled`
- No audio files stored
- All processing on-device

### Settings Integration

**Voice Input Toggle:**

```
┌──────────────────────────┐
│ 🎤 Voice Input          │
│ Add expenses and debts   │
│ by speaking             │
│                   [ON]  │
└──────────────────────────┘
```

**Location:** Settings → Preferences section

**Functionality:**
- Toggle on/off
- Saves to SharedPreferences
- Shows snackbar feedback
- Disables all voice features when off

### Accessibility Features

**Visual Feedback:**
- Pulsing mic icon during listening
- Green for active, gray for inactive
- Animated waveforms (optional)
- Text display of recognized speech

**Audio Feedback:**
- TTS confirmation: "Transaction saved"
- Error sounds for failures
- Success chime

**Error Handling:**
- Clear error messages
- Retry button
- Auto-restart after 2 seconds
- Fallback to manual entry

### Performance Metrics

**Target Metrics:**
- Recognition latency: < 500ms
- Parse accuracy: > 85%
- Battery impact: < 2% per hour
- Offline availability: 100%

**Supported Scenarios:**
- Works offline (pre-downloaded language packs)
- Low bandwidth environments
- Background noise filtering
- Multiple accents support

### Future Enhancements

**Planned Features:**
- Context awareness (time-based suggestions)
- Multi-turn conversations
- Voice-driven analytics queries
- Budget alerts via TTS
- Recurring transaction setup by voice

---

## 📱 Screen-by-Screen Breakdown

### 1. Home Screen 🏠

**Layout Structure:**

```
┌──────────────────────────────────┐
│ AppBar                    💬     │
│ "Good Morning" | Chat Icon 💬    │
│ "Welcome!"                       │
├──────────────────────────────────┤
│                                  │
│  ┌────────────────────────────┐ │
│  │    TOTAL MONEY CARD        │ │
│  │  💼 Wallet Icon   🔼Surplus │ │
│  │  "Total Money"              │ │
│  │  ₹ 12,500                   │ │
│  │  ℹ️ Income+Repay-Exp-Loans │ │
│  └────────────────────────────┘ │
│                                  │
│  ┌────────────────────────────┐ │
│  │    DEBT STATUS CARD        │ │
│  │    "Debt Status"           │ │
│  │      😃/😟 Monster          │ │
│  │   ▓▓▓▓▓░░░░░ Progress      │ │
│  │  You Owe | You Are Owed   │ │
│  │  ₹2,000  |  ₹1,500        │ │
│  │  [Manage Debts Button]    │ │
│  └────────────────────────────┘ │
│                                  │
│  Quick Actions                   │
│  ┌────┐  ┌────┐  ┌────┐        │
│  │ 📈 │  │ 🛒 │  │ 👥 │        │
│  │Add │  │Add │  │Add │        │
│  │Inc │  │Exp │  │Dbt │        │
│  └────┘  └────┘  └────┘        │
└──────────────────────────────────┘
```

**Key Elements:**

1. **Total Money Card** (Gradient Background)
   - Wallet icon in frosted glass container (24px)
   - Status badge: "Surplus" (green) / "Deficit" (red)
   - Label: "Total Money" (15px)
   - Amount: Large display "₹XX,XXX" (42px)
   - Info tooltip with balance formula (11px)
   - Green gradient if positive, red if negative
   - Border radius: 20px
   - Padding: 20px
   - Shadow with matching color

2. **Debt Status Card** (White Background)
   - Title: "Debt Status" (17px bold)
   - Animated debt monster (70px circle)
     - 😟 Red if debt exists
     - 😊 Green if debt-free
     - Bouncing animation
   - Progress bar (red→green)
   - Two columns:
     - "You Owe" | "You Are Owed"
     - Red amount | Green amount (18px bold)
   - "Manage Debts" button

3. **Quick Action Buttons**
   - 3 equal-width buttons
   - Icon (26px) + Label (12px)
   - Color-coded borders:
     - Add Income: Green (#4CAF50)
     - Add Expense: Orange (#FF5722)
     - Add Debt: Purple (#9C27B0)

**Interactions:**
- Tap Total Money → Navigate to Income Management
- Tap Debt Card → Navigate to Debt Management
- Tap Quick Actions → Open respective forms
- Chat icon → Open AI Chatbot

---

### 2. Income Management Screen 💰

**Layout:**

```
┌──────────────────────────────────┐
│ "Income Management"  🎯 Goal     │
├──────────────────────────────────┤
│  ┌────────────────────────────┐ │
│  │   TOTAL INCOME CARD        │ │
│  │   "This Month's Income"    │ │
│  │   ₹ 15,000                 │ │
│  └────────────────────────────┘ │
│                                  │
│  ┌────────────────────────────┐ │
│  │   GOAL PROGRESS            │ │
│  │   ₹15,000 / ₹20,000       │ │
│  │   ▓▓▓▓▓▓▓▓░░ 75%          │ │
│  │   "₹5,000 more to goal!"  │ │
│  └────────────────────────────┘ │
│                                  │
│  Income Breakdown               │
│  ┌────────────────────────────┐ │
│  │ Daily Wages     ₹8,000 53%│ │
│  │ ▓▓▓▓▓▓▓▓▓▓░░░░░░░░░       │ │
│  └────────────────────────────┘ │
│  ┌────────────────────────────┐ │
│  │ Freelance      ₹5,000 33% │ │
│  │ ▓▓▓▓▓▓░░░░░░░░░░░░░░      │ │
│  └────────────────────────────┘ │
│                                  │
│  🎤 Voice Input Button          │
│  📋 Income History List         │
└──────────────────────────────────┘
```

**Key Features:**
- Set/edit monthly income goal
- Visual progress bar
- Source-wise breakdown with percentages
- Voice input: "Earned ₹500"
- Recurring income setup
- Color-coded bars

---

### 3. Add Income Screen 📈

**Form Fields:**

```
┌──────────────────────────────────┐
│ ← "Add Income"         🎤 Voice  │
├──────────────────────────────────┤
│                                  │
│  Amount *                        │
│  ┌────────────────────────────┐ │
│  │ ₹ __________              │ │
│  └────────────────────────────┘ │
│                                  │
│  Source *                        │
│  ┌────────────────────────────┐ │
│  │ Daily Wages ▼             │ │
│  └────────────────────────────┘ │
│  • Daily Wages                   │
│  • Freelance                     │
│  • Business                      │
│  • Other                         │
│                                  │
│  Date                            │
│  ┌────────────────────────────┐ │
│  │ 📅 Oct 4, 2025            │ │
│  └────────────────────────────┘ │
│                                  │
│  ☑ Recurring Income?            │
│  Frequency: Monthly ▼            │
│  Day: 1st ▼                      │
│                                  │
│  Notes (Optional)                │
│  ┌────────────────────────────┐ │
│  │ ___________               │ │
│  └────────────────────────────┘ │
│                                  │
│  ┌────────────────────────────┐ │
│  │    [ADD INCOME] ✓         │ │
│  └────────────────────────────┘ │
└──────────────────────────────────┘
```

**Validation:**
- Amount: Required, positive number
- Source: Required, dropdown
- Recurring: Optional with sub-fields

---

### 4. Add Expense Screen 🛒

**Category Selection:**

```
┌──────────────────────────────────┐
│ ← "Add Expense"        🎤 Voice  │
├──────────────────────────────────┤
│  Select Category                 │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐   │
│  │🍔  │ │🚌  │ │📄  │ │🛍️  │   │
│  │Food│ │Trvl│ │Bill│ │Shop│   │
│  └────┘ └────┘ └────┘ └────┘   │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐   │
│  │🏥  │ │🎬  │ │🎓  │ │📦  │   │
│  │Hlth│ │Ent │ │Edu │ │Misc│   │
│  └────┘ └────┘ └────┘ └────┘   │
│                                  │
│  Amount *                        │
│  ┌────────────────────────────┐ │
│  │ ₹ __________              │ │
│  └────────────────────────────┘ │
│                                  │
│  Date 📅                         │
│  Notes 📝                        │
│                                  │
│  ┌────────────────────────────┐ │
│  │    [ADD EXPENSE] ✓        │ │
│  └────────────────────────────┘ │
└──────────────────────────────────┘
```

**Categories:**
- 🍔 Food (#FF5722)
- 🚌 Travel (#2196F3)
- 📄 Bills (#F44336)
- 🛍️ Shopping (#9C27B0)
- 🏥 Health (#4CAF50)
- 🎬 Entertainment (#FF9800)
- 🎓 Education (#3F51B5)
- 📦 Misc (#607D8B)

---

### 5. Add Debt Screen 👥

**Direction Toggle:**

```
┌──────────────────────────────────┐
│ ← "Add Debt"           🎤 Voice  │
├──────────────────────────────────┤
│  Debt Type                       │
│  ┌──────────┐  ┌──────────┐    │
│  │ 😰 I Owe │  │😊 Owed  │    │
│  │  (Red)   │  │ to Me   │    │
│  │          │  │ (Green) │    │
│  └──────────┘  └──────────┘    │
│                                  │
│  Person Name *                   │
│  ┌────────────────────────────┐ │
│  │ 👤 __________             │ │
│  └────────────────────────────┘ │
│                                  │
│  Amount *                        │
│  ┌────────────────────────────┐ │
│  │ ₹ __________              │ │
│  └────────────────────────────┘ │
│                                  │
│  Due Date 📅                     │
│  Description (Optional)          │
│                                  │
│  ⚠️ Warning (if I Owe):         │
│  "This will reduce your balance"│
│                                  │
│  ┌────────────────────────────┐ │
│  │    [ADD DEBT] ✓           │ │
│  └────────────────────────────┘ │
└──────────────────────────────────┘
```

---

### 6. Debt Management Screen 💳

**Debt List:**

```
┌──────────────────────────────────┐
│ ← "Debt Management"              │
├──────────────────────────────────┤
│  Summary                         │
│  ┌──────────┐  ┌──────────┐    │
│  │ You Owe  │  │ Owed to │    │
│  │ ₹2,000   │  │ Me      │    │
│  │   😰     │  │ ₹1,500  │    │
│  └──────────┘  └──────────┘    │
│                                  │
│  Active Debts                    │
│  ┌────────────────────────────┐ │
│  │ 😰 Raj Kumar              │ │
│  │ ₹1,200 / ₹2,000           │ │
│  │ ▓▓▓▓▓▓░░░░ 60%           │ │
│  │ Due: Oct 15, 2025         │ │
│  │ [Pay] [Details]           │ │
│  └────────────────────────────┘ │
│                                  │
│  ┌────────────────────────────┐ │
│  │ 😊 Priya Singh            │ │
│  │ ₹800 / ₹1,500             │ │
│  │ ▓▓▓▓▓▓▓▓░░ 53%           │ │
│  │ Due: Oct 20, 2025         │ │
│  │ [Remind] [Details]        │ │
│  └────────────────────────────┘ │
│                                  │
│  [+ Add Debt]                    │
└──────────────────────────────────┘
```

**Payment Dialog:**

```
┌────────────────────────┐
│ Pay Debt - Raj Kumar   │
├────────────────────────┤
│ Remaining: ₹800        │
│                        │
│ Payment Amount         │
│ ┌────────────────────┐│
│ │ ₹ ______          ││
│ └────────────────────┘│
│                        │
│ [Quick: ₹100] [₹500]  │
│ [Full: ₹800]          │
│                        │
│ ┌────────────────────┐│
│ │  [Confirm] ✓      ││
│ └────────────────────┘│
└────────────────────────┘
```

---

### 7. Gamification Screen 🏆

**Achievement System:**

```
┌──────────────────────────────────┐
│ "Achievements"                   │
├──────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐    │
│  │ 👹 Debt  │  │ 🐷Saving│    │
│  │ Monster  │  │  Pig    │    │
│  │ 60% ⬇️   │  │ 30% ⬆️   │    │
│  └──────────┘  └──────────┘    │
│                                  │
│  ┌────────────────────────────┐ │
│  │ 🏆 Total Points            │ │
│  │    180 Points              │ │
│  └────────────────────────────┘ │
│                                  │
│  Your Achievements              │
│  ┌────────────────────────────┐ │
│  │ ✅ First Step              │ │
│  │ Added first expense        │ │
│  │                       10pts│ │
│  └────────────────────────────┘ │
│                                  │
│  ┌────────────────────────────┐ │
│  │ ✅ Debt Warrior            │ │
│  │ Started tracking debts     │ │
│  │                       20pts│ │
│  └────────────────────────────┘ │
│                                  │
│  ┌────────────────────────────┐ │
│  │ ✅ Savings Beginner        │ │
│  │ Saved ₹1000                │ │
│  │                       50pts│ │
│  └────────────────────────────┘ │
│                                  │
│  ┌────────────────────────────┐ │
│  │ ✅ Debt Slayer             │ │
│  │ Repaid 50% of debt         │ │
│  │                      100pts│ │
│  └────────────────────────────┘ │
│                                  │
│  ┌────────────────────────────┐ │
│  │ 🔒 Savings Master          │ │
│  │ Save ₹5000            200pts│
│  └────────────────────────────┘ │
│                                  │
│  ┌────────────────────────────┐ │
│  │ 🔒 Debt Free Hero          │ │
│  │ Completely debt free  500pts│
│  └────────────────────────────┘ │
│                                  │
│  ┌────────────────────────────┐ │
│  │ 🎉 Congratulations!        │ │
│  │ You're doing great!        │ │
│  │ Unlock more achievements.  │ │
│  └────────────────────────────┘ │
└──────────────────────────────────┘
```

**Achievement Cards:**
- Unlocked: White background, green border, colored icon
- Locked: Gray background, gray icon, lock icon
- Points displayed in badge

---

### 8. Insights Screen 📊

**Analytics Dashboard:**

```
┌──────────────────────────────────┐
│ "Insights"                       │
├──────────────────────────────────┤
│  Monthly Summary                 │
│  ┌────────────────────────────┐ │
│  │ Income vs Expenses         │ │
│  │ 📊 Bar Chart               │ │
│  └────────────────────────────┘ │
│                                  │
│  Spending by Category           │
│  ┌────────────────────────────┐ │
│  │ 🥧 Pie Chart               │ │
│  │ • Food 40%                 │ │
│  │ • Travel 25%               │ │
│  │ • Bills 20%                │ │
│  │ • Others 15%               │ │
│  └────────────────────────────┘ │
│                                  │
│  Trends                          │
│  ┌────────────────────────────┐ │
│  │ 📈 Line Graph              │ │
│  │ Last 6 Months              │ │
│  └────────────────────────────┘ │
└──────────────────────────────────┘
```

---

### 9. Settings Screen ⚙️

**Settings Options:**

```
┌──────────────────────────────────┐
│ "Settings"                       │
├──────────────────────────────────┤
│  Profile                         │
│  ┌────────────────────────────┐ │
│  │ 👤 Rahul Sharma            │ │
│  │ rahul@example.com          │ │
│  └────────────────────────────┘ │
│                                  │
│  Preferences                     │
│  📱 Language      English ▶     │
│  💰 Currency      INR (₹) ▶     │
│  📅 Income Day    1st ▶          │
│  💵 Monthly Inc   ₹10,000 ▶     │
│                                  │
│  Security                        │
│  🔐 Change PIN          ▶        │
│  👆 Biometric      [Toggle]     │
│                                  │
│  Data                            │
│  ☁️ Backup Data         ▶        │
│  📥 Export CSV          ▶        │
│  ⚠️ Clear All Data      ▶        │
│                                  │
│  About                           │
│  ℹ️ Version 1.0.0               │
│  📧 Contact Support     ▶        │
│  📜 Privacy Policy      ▶        │
│                                  │
│  🚪 Logout                       │
└──────────────────────────────────┘
```

---

### 10. Chatbot Screen 💬

**AI Assistant:**

```
┌──────────────────────────────────┐
│ ← "Financial Assistant"  🤖      │
├──────────────────────────────────┤
│                                  │
│  ┌────────────────────────────┐ │
│  │ Hi! I can help you with:   │ │
│  │ • Expense tracking         │ │
│  │ • Budget planning          │ │
│  │ • Debt advice              │ │
│  │ • Savings tips             │ │
│  └────────────────────────────┘ │
│                                  │
│  You: "How much did I spend     │
│        on food this month?"     │
│                                  │
│  ┌────────────────────────────┐ │
│  │ 🤖 You spent ₹3,200 on     │ │
│  │    food in October.        │ │
│  │    That's 40% of your      │ │
│  │    total expenses.         │ │
│  └────────────────────────────┘ │
│                                  │
│  Quick Actions                   │
│  [Add Expense] [Check Balance]  │
│  [Debt Status] [Savings Tips]   │
│                                  │
│  ┌────────────────────────────┐ │
│  │ Type a message...      🎤  │ │
│  └────────────────────────────┘ │
└──────────────────────────────────┘
```

---

## 🎮 Gamification Elements

### Achievement System

**Achievement Tiers:**

| Achievement | Icon | Points | Trigger | Visual |
|-------------|------|--------|---------|--------|
| **First Step** | ➕ | 10 | Add first expense | Unlocked card, green border |
| **Debt Warrior** | 🛡️ | 20 | Create first debt entry | Shield icon, green |
| **Savings Beginner** | 🐷 | 50 | Save ₹1,000 | Pink piggy bank |
| **Debt Slayer** | ⚔️ | 100 | Pay 50% of debt | Military medal icon |
| **Savings Master** | ⭐ | 200 | Save ₹5,000 | Gold star, locked |
| **Debt Free Hero** | 🏆 | 500 | Zero debt | Trophy, locked |

### Visual Feedback

**Debt Monster Animation:**
```css
/* Monster shrinks as debt decreases */
size = base_size * (1 - debt_progress * 0.7)

/* Color changes */
color: debt > 0 ? #F44336 : #4CAF50

/* Emotion */
icon: debt > 0 ? '😟' : '😊'
```

**Savings Pig Animation:**
```css
/* Bounces when savings increase */
animation: bounce 0.8s ease-in-out infinite

/* Grows with savings */
size = base_size * (1 + savings_progress * 0.3)
```

**Progress Bars:**
- Red background (debt/negative)
- Green fill (progress/positive)
- Animated fill on change
- Percentage label

**Motivational Messages:**
```
Debt < 50%: "Great progress! Keep going! 💪"
Debt < 25%: "Almost there! You're doing amazing! 🌟"
Debt = 0: "Congratulations! You're debt free! 🎉"
Savings > ₹1000: "Fantastic savings! Keep it up! 🏆"
```

---

## 📊 Data Models

### User Model

```typescript
interface User {
  id: string;
  name: string;
  email?: string;
  pinHash: string;
  monthlyIncome?: number;
  incomeDay?: number;
  monthlyIncomeGoal?: number;
  language: 'en' | 'hi' | 'mr';
  createdAt: DateTime;
  updatedAt: DateTime;
}
```

### Income Model

```typescript
interface Income {
  id: string;
  userId: string;
  amount: number;
  source: 'Daily Wages' | 'Freelance' | 'Business' | 'Other';
  date: DateTime;
  isRecurring: boolean;
  frequency?: 'daily' | 'weekly' | 'monthly';
  recurringDay?: number;
  notes?: string;
  createdAt: DateTime;
}
```

### Expense Model

```typescript
interface Expense {
  id: string;
  userId: string;
  amount: number;
  category: 'food' | 'travel' | 'bills' | 'shopping' | 
            'health' | 'entertainment' | 'education' | 'misc';
  date: DateTime;
  description?: string;
  createdAt: DateTime;
}
```

### Debt Model

```typescript
interface Debt {
  id: string;
  userId: string;
  personName: string;
  amount: number;
  paidAmount: number;
  direction: 'owe' | 'owed'; // I owe / Owed to me
  description?: string;
  dueDate: DateTime;
  isSettled: boolean;
  createdAt: DateTime;
  updatedAt: DateTime;
}
```

---

## 🌍 Multi-Language Support

### Supported Languages

1. **English (en)** - Default
2. **Hindi (hi)** - हिंदी
3. **Marathi (mr)** - मराठी

### Translation Keys

**Navigation:**
```json
{
  "en": {
    "home": "Home",
    "income": "Income",
    "insights": "Insights",
    "achievements": "Achievements",
    "settings": "Settings"
  },
  "hi": {
    "home": "होम",
    "income": "आय",
    "insights": "जानकारी",
    "achievements": "उपलब्धियां",
    "settings": "सेटिंग्स"
  },
  "mr": {
    "home": "होम",
    "income": "उत्पन्न",
    "insights": "अंतर्दृष्टी",
    "achievements": "यश",
    "settings": "सेटिंग्ज"
  }
}
```

**Home Screen:**
```json
{
  "en": {
    "goodMorning": "Good Morning",
    "totalMoney": "Total Money",
    "surplus": "Surplus",
    "deficit": "Deficit",
    "balanceInfo": "Income + Repayments - Expenses - Loans",
    "debtStatus": "Debt Status",
    "youOwe": "You Owe",
    "youAreOwed": "You Are Owed",
    "quickActions": "Quick Actions",
    "addIncome": "Add Income",
    "addExpense": "Add Expense",
    "addDebt": "Add Debt"
  }
}
```

---

## 🎨 Icons & Emojis

### Icon Library (Material Icons)

**Navigation:**
- Home: `home`
- Income: `account_balance_wallet`
- Insights: `insights`
- Achievements: `emoji_events`
- Settings: `settings`

**Actions:**
- Add: `add_circle`
- Edit: `edit`
- Delete: `delete`
- Save: `check_circle`
- Cancel: `close`
- Back: `arrow_back`
- Voice: `mic`
- Calendar: `calendar_today`
- Info: `info_outline`

**Categories:**
- Food: `restaurant` 🍔
- Travel: `directions_bus` 🚌
- Bills: `receipt` 📄
- Shopping: `shopping_bag` 🛍️
- Health: `local_hospital` 🏥
- Entertainment: `movie` 🎬
- Education: `school` 🎓
- Misc: `category` 📦

**Financial:**
- Money: `currency_rupee` ₹
- Wallet: `account_balance_wallet` 💼
- Trending Up: `trending_up` 📈
- Trending Down: `trending_down` 📉
- Savings: `savings` 🐷
- Shield: `shield` 🛡️
- Trophy: `emoji_events` 🏆
- Star: `star` ⭐
- Medal: `military_tech` ⚔️

**Emotions:**
- Happy: `sentiment_very_satisfied` 😊
- Sad: `sentiment_dissatisfied` 😰
- Neutral: `sentiment_neutral` 😐

### Emoji Usage

**Context-Based:**
- Positive balance: ✅ 💚 📈 🎉
- Negative balance: ❌ ❤️ 📉 😰
- Goals achieved: 🏆 🌟 💪 🎯
- Warnings: ⚠️ ⚡ 🔴
- Success: ✓ ✅ 🎉 👍
- Information: ℹ️ 💡 📊

---

## ✨ Animations & Interactions

### Micro-Interactions

**Button Press:**
```css
scale: 0.95
duration: 100ms
```

**Card Tap:**
```css
elevation: 0 → 8px
duration: 200ms
```

**Toggle Switch:**
```css
translate: 0 → 20px
color: gray → green
duration: 300ms
```

### Page Transitions

**Navigation:**
```css
type: slide
direction: left
duration: 300ms
curve: easeInOut
```

**Modal:**
```css
type: fade + scale
scale: 0.8 → 1.0
opacity: 0 → 1.0
duration: 250ms
```

### Loading States

**Shimmer Effect:**
```css
background: linear-gradient(
  90deg,
  #f0f0f0 25%,
  #e0e0e0 50%,
  #f0f0f0 75%
)
animation: shimmer 2s infinite
```

**Spinner:**
```css
color: #46EC13
size: 36px
strokeWidth: 4px
```

### Data Updates

**Number Counter:**
```javascript
// Animate from old to new value
duration: 500ms
easing: easeOut
format: currency
```

**Progress Bar:**
```javascript
// Smooth fill animation
duration: 600ms
easing: easeInOut
```

### Gamification Animations

**Achievement Unlock:**
```css
1. Scale from 0 → 1.2 → 1.0
2. Fade in
3. Confetti explosion
4. Slide up notification
duration: 1000ms
```

**Debt Monster:**
```css
// Continuous breathing
scale: 0.8 ↔ 1.2
duration: 2000ms
repeat: infinite
reversible: true
```

**Savings Pig:**
```css
// Bouncing
translateY: 0 → 10 → 0
duration: 800ms
repeat: infinite
curve: bounceIn
```

---

## 📐 Responsive Design

### Breakpoints

- Small: < 360px (compact phones)
- Medium: 360px - 600px (standard phones)
- Large: > 600px (tablets)

### Layout Adaptation

**Small Screens:**
- Single column
- Smaller font sizes (-2px)
- Reduced padding (-4px)
- Stacked buttons

**Medium Screens:**
- Standard layout
- Default sizing
- Side-by-side cards

**Large Screens:**
- Two-column layout
- Increased spacing
- Larger touch targets

---

## 🔐 Security Features

**PIN Authentication:**
- 4-6 digit PIN
- SHA-256 hashing
- Biometric option (fingerprint/face)
- Auto-lock after 5 minutes

**Data Storage:**
- Local SQLite database
- Encrypted PIN storage
- No cloud sync (privacy-first)

---

## 🎯 Key Performance Metrics

**App Performance:**
- Launch time: < 2 seconds
- Screen transitions: < 300ms
- Database queries: < 100ms
- Voice input latency: < 500ms

**User Engagement:**
- Daily active tracking
- Achievement unlock rate
- Voice input usage
- Debt repayment progress

---

## 🚀 Technical Stack

**Frontend:**
- Flutter 3.9.2+
- Material Design 3
- Dart

**Database:**
- SQLite (sqflite ^4.0.0)
- Local storage

**Features:**
- Speech-to-text (^7.0.0)
- Shared preferences
- Date formatting

**Platform:**
- Android
- iOS
- Web (future)

---

## 📱 Bottom Navigation

**Structure:**
```
┌─────┬─────┬─────┬─────┬─────┐
│ 🏠  │ 💰  │ 📊  │ 🏆  │ ⚙️  │
│Home │Inc  │Insi │Achv │Sett │
└─────┴─────┴─────┴─────┴─────┘
```

**Styling:**
- Type: Fixed
- Background: White
- Selected color: #46EC13
- Unselected color: Gray
- Label size: 12px
- Icon size: 24px

---

## 📋 Form Guidelines

**Input Fields:**
- Border radius: 12px
- Padding: 16px
- Focus color: #46EC13
- Error color: #F44336
- Label size: 14px
- Input size: 16px

**Buttons:**
- Primary: #46EC13, white text, 16px
- Secondary: White, green border, green text
- Destructive: #F44336, white text
- Disabled: Gray, 50% opacity
- Height: 48px
- Border radius: 12px

**Validation:**
- Real-time on blur
- Error messages below field
- Red border on error
- Green checkmark on valid

---

## 🎨 Component Library

### Cards

**Standard Card:**
```css
background: white
padding: 16px
borderRadius: 16px
shadow: 0 3px 10px rgba(0,0,0,0.05)
```

**Gradient Card:**
```css
background: linear-gradient(135deg, color1, color2)
padding: 20px
borderRadius: 20px
shadow: 0 8px 15px rgba(color, 0.25)
```

### Lists

**List Item:**
```css
padding: 12px 16px
borderBottom: 1px solid #f0f0f0
activeOpacity: 0.7
```

### Dialogs

**Alert Dialog:**
```css
borderRadius: 16px
padding: 24px
maxWidth: 280px
backgroundColor: white
```

---

## 🌟 User Delight Moments

1. **First Income Entry:** Confetti animation 🎉
2. **Debt Paid Off:** Trophy popup + celebration 🏆
3. **Goal Reached:** Congratulations card 🎯
4. **Streak Milestone:** Fire emoji + points 🔥
5. **Savings Growth:** Piggy bank grows larger 🐷

---

## 📱 App Icon & Branding

**App Icon:**
- Background: #46EC13
- Symbol: ₹ (Rupee) in white
- Style: Rounded square
- Size: 1024x1024px

**Splash Screen:**
- Background: #46EC13
- Logo: Rupaya ₹
- Tagline: "Smart Money Management"
- Duration: 2 seconds

---

## 🎯 Success Metrics

**User Retention:**
- Daily open rate: > 40%
- Weekly active users: > 70%
- Monthly retention: > 60%

**Feature Adoption:**
- Voice input usage: > 25%
- Recurring income setup: > 40%
- Achievement engagement: > 50%

**Financial Impact:**
- Debt reduction tracked: Average 30%
- Savings increase: Average ₹2,000/month
- Expense awareness: 80% users

---

This comprehensive PRD covers all aspects of the Rupaya app for building a pixel-perfect web version! 🚀
