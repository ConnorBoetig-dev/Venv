```
frontend/
├── node_modules/              # (created after npm install)
├── public/
│   └── chud.svg              # (your favicon)
├── src/
│   ├── api/
│   │   └── client.ts         # Axios instance with interceptors
│   │
│   ├── assets/
│   │   └── react.svg         # (default from Vite)
│   │
│   ├── components/
│   │   └── Layout/
│   │       ├── Layout.tsx    # Main layout with navigation
│   │       └── Layout.css    # Layout styles
│   │
│   ├── hooks/
│   │   ├── index.ts          # Central export for hooks
│   │   ├── useAuth.ts        # Authentication hook
│   │   ├── useSearch.ts      # Search functionality hook
│   │   └── useUpload.ts      # Upload management hook
│   │
│   ├── pages/
│   │   ├── Dashboard/
│   │   │   ├── Dashboard.tsx # User dashboard page
│   │   │   └── Dashboard.css # Dashboard styles
│   │   │
│   │   ├── Home/
│   │   │   ├── Home.tsx      # Landing page
│   │   │   └── Home.css      # Home page styles
│   │   │
│   │   ├── Login/
│   │   │   ├── Login.tsx     # Login page
│   │   │   └── Login.css     # Login styles (shared auth styles)
│   │   │
│   │   ├── NotFound/
│   │   │   ├── NotFound.tsx  # 404 page
│   │   │   └── NotFound.css  # 404 styles
│   │   │
│   │   ├── Register/
│   │   │   ├── Register.tsx  # Registration page
│   │   │   └── Register.css  # Register styles (extends Login.css)
│   │   │
│   │   ├── Search/
│   │   │   ├── Search.tsx    # Search page (placeholder)
│   │   │   └── Search.css    # Search styles
│   │   │
│   │   └── Upload/
│   │       ├── Upload.tsx    # Upload page (placeholder)
│   │       └── Upload.css    # Upload styles
│   │
│   ├── store/
│   │   └── authStore.ts      # Zustand auth state
│   │
│   ├── types/
│   │   ├── api.ts            # API request/response types
│   │   ├── env.d.ts          # Environment variable types
│   │   ├── index.ts          # Central type exports + utilities
│   │   └── models.ts         # Core data models
│   │
│   ├── utils/               # (empty for now)
│   │   ├── formatters.ts    # (to be created)
│   │   └── validators.ts    # (to be created)
│   │
│   ├── App.css              # Global app styles
│   ├── App.tsx              # Main app with routing
│   ├── index.css            # Tailwind imports + root styles
│   ├── main.tsx             # App entry point with providers
│   └── vite-env.d.ts        # Vite types
│
├── .env.example             # Example environment variables
├── .gitignore
├── biome.json               # Biome linter/formatter config
├── index.html               # HTML entry point
├── package.json             # Dependencies
├── package-lock.json
├── postcss.config.js        # PostCSS config for Tailwind
├── tailwind.config.js       # Tailwind configuration
├── tsconfig.app.json        # App TypeScript config
├── tsconfig.json            # Main TypeScript config
├── tsconfig.node.json       # Node TypeScript config
└── vite.config.ts           # Vite configuration
```

## Future Components to Add:

```
src/
├── components/
│   ├── FileUpload/
│   │   ├── FileUpload.tsx    # Drag-and-drop upload component
│   │   └── FileUpload.css
│   │
│   ├── MediaGrid/
│   │   ├── MediaGrid.tsx     # Grid display of uploads
│   │   └── MediaGrid.css
│   │
│   ├── SearchBar/
│   │   ├── SearchBar.tsx     # Search input with suggestions
│   │   └── SearchBar.css
│   │
│   ├── UploadModal/
│   │   ├── UploadModal.tsx   # Upload detail view modal
│   │   └── UploadModal.css
│   │
│   └── SearchResults/
│       ├── SearchResults.tsx  # Search results display
│       └── SearchResults.css
```

## File Creation Commands:

To create all the folders properly:

```bash
# From frontend/src directory
cd frontend/src

# Create all page directories
mkdir -p pages/{Home,Login,Register,Dashboard,Upload,Search,NotFound}

# Create component directories
mkdir -p components/Layout

# Future component directories (when needed)
mkdir -p components/{FileUpload,MediaGrid,SearchBar,UploadModal,SearchResults}
```

This structure follows the pattern of keeping related files together (component + styles in same folder) while maintaining clear separation between:
- **pages/** - Route components
- **components/** - Reusable UI components  
- **hooks/** - Custom React hooks
- **types/** - TypeScript definitions
- **api/** - API client configuration
- **store/** - Global state management
- **utils/** - Helper functions


# THEME

# PG-VENV Design System Documentation
**Smart Camera Roll with Semantic Search**

---

## 🎯 Design Philosophy

**Concept**: "Dark Liquid Glass"
A premium, modern interface that combines sleek minimalism with subtle depth and sophistication. The design should feel effortless and intuitive while showcasing cutting-edge AI-powered semantic search capabilities.

**Core Principles**:
- Sleek and modern aesthetic with Apple-like polish
- Unique and experimental without being complex
- Interface remains neutral to let media content shine
- AI functionality feels seamless and invisible
- Efficient and powerful search experience

---

## 🎨 Visual Style

### Color Palette
```css
/* Primary Colors */
--base-black: #1B1B1B;           /* Pure matte charcoal background */
--accent-turquoise: #065465;      /* Rare highlights and focus states */

/* Glass Elements */
--glass-overlay: rgba(255, 255, 255, 0.08);  /* Semi-transparent panels */
--glass-border: rgba(255, 255, 255, 0.12);   /* Subtle borders */

/* Supporting Colors */
--text-primary: #FFFFFF;          /* Primary text */
--text-secondary: #B0B0B0;        /* Secondary text */
--text-muted: #808080;            /* Tertiary text */
```

### Glass Transparency
- **Medium blur effect**: iOS Control Center style but 20% more transparent
- **Frosted glass panels** for navigation, search, and overlay elements
- **Subtle depth** through layering and soft shadows
- **Translucent overlays** that maintain readability

---

## 🖼️ Layout & Grid System

### Media Grid
- **Experimental/unique layout** rather than standard uniform grid
- **Masonry-style arrangement** with intelligent spacing
- **Smooth rearrangement** when filtering - images flow like liquid into new positions
- **No gaps** left behind when items filter out
- **Gentle water-flowing transitions** with eased animations

### Responsive Behavior
- Grid adapts intelligently across screen sizes
- Glass elements scale appropriately
- Search remains contextual and accessible

---

## 🔍 Search Experience

### Contextual Search Bar
The search bar adapts based on user location within the app:
- **Prominent on landing page** - hero element
- **Integrated into navigation** when browsing
- **Expands intelligently** when needed
- **Frosted glass effect** with turquoise focus state

### Real-Time Semantic Filtering
**Revolutionary Feature**: Live filtering as users type

**Behavior**:
1. User types "flower" → All flower images appear
2. User types "flower red" → Non-red flowers fade out elegantly  
3. User types "flower red tall" → Only tall red flowers remain

**Technical Implementation**:
- **Instant feedback** as user types (no delay)
- **Smooth fade transitions** for items leaving view
- **Liquid rearrangement** as grid rebuilds
- **Visual funnel effect** creating satisfying narrowing experience

---

## ✨ Animation Guidelines

### Philosophy
**Sleek over spectacular** - refined animations that enhance usability without distraction

### Animation Types
- **Smooth morphing transitions** between states
- **Gentle fade in/out** for filtering
- **Eased slide animations** for grid rearrangement
- **Subtle depth effects** on hover/interaction
- **No particles or excessive effects** - keep it sophisticated

### Timing
- **Fast but not jarring**: 200-300ms for most transitions
- **Staggered animations** for grid items (subtle delay)
- **Immediate response** for search filtering

---

## 🎭 Interaction Patterns

### Hover States
- **Subtle lift effect** on media items
- **Soft glow** using turquoise accent
- **Glass elements** become slightly more opaque

### Selection States
- **Thin turquoise border** on selected items
- **Slight opacity increase** for selected state
- **Smooth transitions** in/out of selection

### Loading States
- **Elegant loading indicators** using turquoise
- **Skeleton screens** with glass-like shimmer
- **Progressive disclosure** as content loads

---

## 📱 Component Specifications

### Glass Panels
```css
background: rgba(255, 255, 255, 0.08);
backdrop-filter: blur(20px);
border: 1px solid rgba(255, 255, 255, 0.12);
border-radius: 12px;
```

### Search Bar
- **Prominent glass container** with medium blur
- **Turquoise focus ring** (#065465)
- **Contextual sizing** based on location
- **Smooth expand/collapse** animations

### Media Items
- **Subtle rounded corners** (8px)
- **Smooth hover lift** (4px translate)
- **Selection highlight** with turquoise accent
- **Aspect ratio preservation**

---

## 🚀 Implementation Notes

### Technology Considerations
- **CSS backdrop-filter** for glass effects
- **CSS Grid/Flexbox** for adaptive layouts
- **Intersection Observer** for efficient loading
- **CSS transitions** for smooth animations
- **Debounced search** for real-time filtering

### Performance Priorities
- **Smooth 60fps animations** on all interactions
- **Efficient rendering** for large media collections
- **Optimized images** with progressive loading
- **Minimal layout thrash** during filtering

### Accessibility
- **High contrast ratios** maintained with dark theme
- **Focus indicators** clearly visible with turquoise accents
- **Reduced motion** options for sensitive users
- **Keyboard navigation** fully supported

---

## 🎪 Unique Selling Points

1. **Real-time semantic filtering** - unprecedented in photo apps
2. **Dark liquid glass aesthetic** - premium and distinctive
3. **Contextual search experience** - adapts to user context
4. **Effortless AI integration** - power without complexity
5. **Liquid grid animations** - organic and satisfying

---

**Target Feeling**: Users should feel like they're using the future of photo organization - powerful, elegant, and almost magical in its simplicity.



  📋 The Pattern:

  ✅ Use CSS files for:
  - Complex animations & keyframes (like landing page rotations, liquid
  flows)
  - Custom utility classes (like pgv-glass, auth-page-with-grid)
  - Component-specific patterns that would be verbose in Tailwind

  ✅ Use Tailwind for:
  - Layout & spacing (flex, grid, p-8, gap-4)
  - Colors & states (text-white, bg-black/30, hover:scale-105)
  - Simple responsive design (md:grid-cols-2, lg:grid-cols-3)


