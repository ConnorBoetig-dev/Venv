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

