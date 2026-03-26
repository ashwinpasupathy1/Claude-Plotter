// ArchitectureGuideCatalog.swift — Comprehensive developer reference for the Refraction codebase.
// Covers architecture, data flow, API endpoints, analyzers, models, and file formats.

import Foundation

// MARK: - Model

struct ArchitectureEntry: Identifiable {
    let id: String
    let category: ArchitectureCategory
    let title: String
    let summary: String
    let details: String
    let relatedFiles: [String]
    let methods: [MethodSignature]
}

struct MethodSignature: Identifiable {
    let id: String
    let signature: String
    let description: String

    init(signature: String, description: String) {
        self.id = signature
        self.signature = signature
        self.description = description
    }
}

enum ArchitectureCategory: String, CaseIterable, Identifiable {
    case architecture = "Architecture"
    case dataFlow = "Data Flow"
    case pythonEngine = "Python Engine"
    case swiftRenderers = "Swift Renderers"
    case models = "Models"
    case apiEndpoints = "API Endpoints"
    case analysisPipeline = "Analysis Pipeline"
    case fileFormats = "File Formats"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .architecture:      return "building.2"
        case .dataFlow:          return "arrow.triangle.swap"
        case .pythonEngine:      return "gearshape.2"
        case .swiftRenderers:    return "paintbrush"
        case .models:            return "cube"
        case .apiEndpoints:      return "network"
        case .analysisPipeline:  return "function"
        case .fileFormats:       return "doc.zipper"
        }
    }
}

// MARK: - Catalog

enum ArchitectureGuideCatalog {

    /// Look up an entry by its id.
    static func entry(for id: String) -> ArchitectureEntry? {
        all.first { $0.id == id }
    }

    /// All entries in a given category.
    static func entries(in category: ArchitectureCategory) -> [ArchitectureEntry] {
        all.filter { $0.category == category }
    }

    // MARK: - Complete Catalog

    static let all: [ArchitectureEntry] = [

        // ═══════════════════════════════════════════════════════════════
        // ARCHITECTURE
        // ═══════════════════════════════════════════════════════════════

        ArchitectureEntry(
            id: "arch_overview",
            category: .architecture,
            title: "System Overview",
            summary: "SwiftUI frontend communicating with a Python FastAPI backend over localhost HTTP.",
            details: """
                Refraction is a GraphPad Prism-style scientific plotting and analysis app for macOS. \
                The architecture follows a strict client-server split:

                The SwiftUI app (RefractionApp/) handles all user interaction, chart rendering via \
                Apple's Charts framework, and project state management. It communicates with a Python \
                FastAPI server over HTTP on 127.0.0.1:7331.

                The Python backend (refraction/) is a pure analysis engine. It reads Excel/CSV data, \
                computes descriptive statistics, runs statistical tests, and returns plain JSON dicts. \
                It has zero knowledge of colors, fonts, axes, or any visual properties.

                This separation exists so that the engine can be tested independently (767 tests, ~3 seconds), \
                and so the renderer can change (e.g., from Plotly to SwiftUI Charts) without touching the \
                statistical computation layer.

                Key invariants:
                - The renderer knows nothing about statistics (no p-values, no test types, no raw data).
                - The engine knows nothing about visuals (no colors, no fonts, no axis styles).
                - Visual formatting lives in FormatGraphSettings and FormatAxesSettings on the Swift side.
                - All math lives in refraction/core/stats.py.
                """,
            relatedFiles: [
                "RefractionApp/Refraction/App/RefractionApp.swift",
                "RefractionApp/Refraction/App/AppState.swift",
                "refraction/server/api.py",
                "refraction/analysis/engine.py",
            ],
            methods: []
        ),

        ArchitectureEntry(
            id: "arch_project_hierarchy",
            category: .architecture,
            title: "Project Hierarchy",
            summary: "Project -> Experiment -> (DataTables, Graphs, Analyses) — the data ownership model.",
            details: """
                The project hierarchy mirrors GraphPad Prism's organizational model:

                AppState (root)
                  -> experiments: [Experiment]
                    -> dataTables: [DataTable]      // each has a TableType (Column, XY, Grouped, etc.)
                    -> graphs: [Graph]               // each links to a DataTable by ID
                    -> analyses: [Analysis]           // each links to a DataTable by ID

                An Experiment is the top-level container for related work. It owns multiple DataTables, \
                and each Graph or Analysis references one DataTable by UUID.

                DataTable stores the table type (which constrains valid chart types) and the file path \
                to the uploaded data file. The table type system follows Prism exactly: XY, Column, \
                Grouped, Contingency, Survival, Parts of whole, Multiple variables, Nested, plus \
                additional types (Two-Way, Comparison, Meta-Analysis).

                Graph holds the chart type, ChartConfig (sent to the engine), cached ChartSpec \
                (received from the engine), and format settings (FormatGraphSettings, FormatAxesSettings). \
                It also tracks the current RenderStyle preset.

                Analysis stores statistical results (StatsResult) from the /analyze-stats endpoint.

                Navigation uses activeExperimentID, activeItemID, and activeItemKind to track what \
                the user has selected in the sidebar navigator.
                """,
            relatedFiles: [
                "RefractionApp/Refraction/App/AppState.swift",
                "RefractionApp/Refraction/Models/Experiment.swift",
                "RefractionApp/Refraction/Models/DataTable.swift",
                "RefractionApp/Refraction/Models/Graph.swift",
                "RefractionApp/Refraction/Models/Analysis.swift",
            ],
            methods: [
                MethodSignature(
                    signature: "Experiment.addDataTable(type:label:) -> DataTable",
                    description: "Create a new data table with the given TableType inside this experiment."
                ),
                MethodSignature(
                    signature: "Experiment.addGraph(chartType:dataTableID:label:) -> Graph?",
                    description: "Create a new graph linked to a data table. Returns nil if a graph with the same label already exists."
                ),
                MethodSignature(
                    signature: "Experiment.addAnalysis(dataTableID:label:analysisType:) -> Analysis",
                    description: "Create a new statistical analysis linked to a data table."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "arch_server_lifecycle",
            category: .architecture,
            title: "Server Lifecycle",
            summary: "The Python server starts as a daemon thread on app launch and runs on port 7331.",
            details: """
                On app launch, RefractionApp.swift calls PythonServer to start the FastAPI backend. \
                The server runs as a daemon thread via uvicorn on 127.0.0.1:7331.

                The start_server() function in api.py creates a background thread running uvicorn.run(). \
                Because it is a daemon thread, it terminates automatically when the app exits. \
                Uploaded files are stored in a temp directory ($TMPDIR/refraction-uploads/) which is \
                cleaned up via an atexit handler.

                The APIClient on the Swift side is an actor (thread-safe singleton) that uses URLSession \
                with a 30-second request timeout and 60-second resource timeout. All API calls are async.

                Health checking: the app can call GET /health which returns {"status": "ok"} to verify \
                the server is running before making analysis requests.

                Logs are written to ~/Library/Logs/Refraction/api.log for debugging.
                """,
            relatedFiles: [
                "RefractionApp/Refraction/App/RefractionApp.swift",
                "RefractionApp/Refraction/Services/APIClient.swift",
                "refraction/server/api.py",
            ],
            methods: [
                MethodSignature(
                    signature: "start_server() -> None",
                    description: "Start the FastAPI server in a background daemon thread on port 7331."
                ),
                MethodSignature(
                    signature: "APIClient.shared",
                    description: "Singleton actor instance for all HTTP communication with the Python backend."
                ),
                MethodSignature(
                    signature: "APIClient.health() async throws -> Bool",
                    description: "Check if the Python server is healthy (GET /health)."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "arch_table_types",
            category: .architecture,
            title: "Table Types & Chart Constraints",
            summary: "Each TableType constrains which chart types can be created, following Prism conventions.",
            details: """
                The TableType enum defines 11 data table types. The first 8 match GraphPad Prism exactly:

                - XY: scatter, line, area_chart, curve_fit, bubble
                - Column: bar, box, violin, dot_plot, histogram, raincloud, column_stats, lollipop, ecdf, qq_plot
                - Grouped: grouped_bar, stacked_bar, heatmap
                - Contingency: contingency, chi_square_gof
                - Survival: kaplan_meier
                - Parts of whole: waterfall, pyramid
                - Multiple variables: heatmap, scatter, bubble
                - Nested: subcolumn_scatter, bar, box, dot_plot

                Three additional types extend beyond Prism:
                - Two-Way: two_way_anova
                - Comparison: before_after, bland_altman, repeated_measures
                - Meta-Analysis: forest_plot

                When creating a new graph, the UI only offers chart types valid for the linked \
                data table's TableType. This prevents invalid combinations like trying to create \
                a survival curve from column data.
                """,
            relatedFiles: [
                "RefractionApp/Refraction/Models/TableType.swift",
            ],
            methods: [
                MethodSignature(
                    signature: "TableType.validChartTypes -> [ChartType]",
                    description: "Returns the list of chart types valid for this table type."
                ),
                MethodSignature(
                    signature: "TableType.defaultChartType -> ChartType",
                    description: "The first valid chart type, used as default when creating new graphs."
                ),
            ]
        ),

        // ═══════════════════════════════════════════════════════════════
        // DATA FLOW
        // ═══════════════════════════════════════════════════════════════

        ArchitectureEntry(
            id: "flow_upload",
            category: .dataFlow,
            title: "Data Upload Pipeline",
            summary: "User drops a file -> POST /upload -> server stores in temp dir -> path returned to Swift.",
            details: """
                When the user imports data (via drag-and-drop or file picker):

                1. The Swift app reads the file and sends it to POST /upload as multipart form data.
                2. The server validates the file extension (.xlsx, .xls, .csv) and size (max 10 MB).
                3. The file is saved with a UUID-based name in $TMPDIR/refraction-uploads/.
                4. The server returns {"ok": true, "path": "/tmp/.../abc123.xlsx", "filename": "original.xlsx"}.
                5. The Swift app stores the server-side path in DataTable.dataFilePath and the \
                   original name in DataTable.originalFileName.

                This path is then used for all subsequent analysis requests. The temp directory \
                is cleaned up on server exit via atexit.

                The upload endpoint accepts .xlsx, .xls, and .csv files. It rejects files larger \
                than 10 MB to prevent memory issues in pandas.
                """,
            relatedFiles: [
                "refraction/server/api.py",
                "RefractionApp/Refraction/Services/APIClient.swift",
                "RefractionApp/Refraction/Models/DataTable.swift",
            ],
            methods: [
                MethodSignature(
                    signature: "POST /upload",
                    description: "Accept .xlsx/.xls/.csv upload via multipart form data; return server-side path."
                ),
                MethodSignature(
                    signature: "APIClient.uploadFile(url:) async throws -> UploadResponse",
                    description: "Upload a local file to the Python server and receive the stored path."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "flow_analyze_render",
            category: .dataFlow,
            title: "Analyze & Render Pipeline",
            summary: "ChartConfig -> POST /render -> analyze() -> _to_chart_spec() -> ChartSpec -> SwiftUI Charts.",
            details: """
                When the user creates or updates a graph, the full pipeline is:

                1. Swift: Graph.chartConfig.toDict() serializes ~40 config properties into a dict.
                2. Swift: APIClient.analyze(chartType:config:) sends POST /render with {chart_type, kw: configDict}.
                3. Python /render endpoint: extracts excel_path from kw, maps Swift config keys \
                   to engine keys (e.g. "error" -> "error_type", "xlabel" -> "x_label").
                4. Python: calls analyze(chart_type, excel_path, config) from the analysis engine.
                5. Engine: dispatches to a dedicated analyzer if one exists in _DEDICATED_ANALYZERS, \
                   otherwise falls through to the generic column-as-groups analysis path.
                6. Analyzer returns a result dict with groups, comparisons, title, etc.
                7. Python /render: calls _to_chart_spec(result, config) to transform the engine output \
                   into the ChartSpec JSON schema that Swift expects.
                8. Python /render: wraps in {"ok": true, "spec": {...}} envelope.
                9. Swift: JSONDecoder decodes RenderResponse -> ChartSpec.
                10. Swift: ChartSpec is stored in Graph.chartSpec and rendered by ChartCanvasView.

                The /render endpoint also supports a _debug flag that includes an engine trace \
                in the response, showing the analysis steps and intermediate values.
                """,
            relatedFiles: [
                "RefractionApp/Refraction/Models/ChartConfig.swift",
                "RefractionApp/Refraction/Services/APIClient.swift",
                "refraction/server/api.py",
                "refraction/analysis/engine.py",
                "RefractionApp/Refraction/Views/Chart/ChartCanvasView.swift",
            ],
            methods: [
                MethodSignature(
                    signature: "ChartConfig.toDict() -> [String: Any]",
                    description: "Serialize all ~40 chart config properties into a dictionary for the API request."
                ),
                MethodSignature(
                    signature: "APIClient.analyze(chartType:config:) async throws -> ChartSpec",
                    description: "Send a render request and decode the ChartSpec response."
                ),
                MethodSignature(
                    signature: "analyze(chart_type, excel_path, config) -> dict",
                    description: "Core engine entry point: reads data, computes stats, returns plain dict."
                ),
                MethodSignature(
                    signature: "_to_chart_spec(result, config) -> dict",
                    description: "Transform analyze() output into the ChartSpec JSON schema for Swift."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "flow_stats_analysis",
            category: .dataFlow,
            title: "Statistical Analysis Pipeline",
            summary: "Analyze Data dialog -> POST /analyze-stats -> StatsResult -> Analysis results sheet.",
            details: """
                The standalone statistical analysis flow (separate from chart rendering) works as:

                1. User opens the Analyze Data dialog and selects an analysis type \
                   (e.g., unpaired t-test, ANOVA, Kruskal-Wallis).
                2. Swift sends POST /analyze-stats with {excel_path, analysis_type, mc_correction, posthoc, control}.
                3. Python reads the data, extracts numeric groups from columns, computes descriptive \
                   statistics (mean, SD, SEM, median, CI95) for each group.
                4. Runs normality tests (Shapiro-Wilk) on each group.
                5. Runs the requested statistical test via _run_stats().
                6. Computes effect sizes (Cohen's d) for pairwise comparisons.
                7. Gets a test recommendation from recommend_test().
                8. Returns {descriptive, normality, comparisons, summary, recommendation}.
                9. Swift creates an Analysis object and stores the StatsResult.
                10. The results are displayed in the ResultsSheetView/ResultsView.

                This pipeline also powers the Stats Wiki dialog's recommendation feature, which \
                uses POST /recommend-test to analyze the data and suggest the best test.
                """,
            relatedFiles: [
                "RefractionApp/Refraction/Views/Sheets/AnalyzeDataDialog.swift",
                "RefractionApp/Refraction/Models/Analysis.swift",
                "RefractionApp/Refraction/Views/Results/ResultsView.swift",
                "refraction/server/api.py",
                "refraction/core/stats.py",
            ],
            methods: [
                MethodSignature(
                    signature: "POST /analyze-stats",
                    description: "Run a statistical analysis: descriptive stats, normality, comparisons, effect sizes."
                ),
                MethodSignature(
                    signature: "POST /recommend-test",
                    description: "Analyze data and recommend the best statistical test based on group count, pairing, and normality."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "flow_format_settings",
            category: .dataFlow,
            title: "Format Settings Flow",
            summary: "FormatGraphSettings and FormatAxesSettings control all visual properties, applied client-side.",
            details: """
                All visual formatting is handled entirely on the Swift side, never touching the engine:

                FormatGraphSettings controls bar properties (width, border, colors), error bar appearance \
                (style, color, thickness), line thickness, symbol size, and point display options.

                FormatAxesSettings controls axis appearance (thickness, color, frame style), grid lines \
                (major/minor, style, color), tick marks (direction, length), font settings (name, sizes \
                for title, axis titles, axis labels), and plot area/page background colors.

                RenderStyle presets (Default, Prism, ggplot2, Matplotlib) modify both settings objects \
                to match the visual style of popular plotting libraries. Each preset sets specific values \
                for all visual properties. The user can also customize individual properties after applying \
                a preset.

                The Format Graph dialog and Format Axes dialog allow full control over these settings. \
                Changes are reflected immediately in the chart canvas.

                The FormatSettingsMerger utility merges user format overrides with ChartSpec defaults \
                when rendering, so engine-provided defaults can be selectively overridden.
                """,
            relatedFiles: [
                "RefractionApp/Refraction/Models/RenderStyle.swift",
                "RefractionApp/Refraction/Models/Graph.swift",
                "RefractionApp/Refraction/Views/Chart/FormatSettingsMerger.swift",
            ],
            methods: [
                MethodSignature(
                    signature: "RenderStyle.apply(to:axes:)",
                    description: "Apply a render style preset, updating both FormatGraphSettings and FormatAxesSettings."
                ),
                MethodSignature(
                    signature: "Graph.applyRenderStyle(_ style: RenderStyle)",
                    description: "Set the render style on a graph and update its format settings."
                ),
            ]
        ),

        // ═══════════════════════════════════════════════════════════════
        // PYTHON ENGINE
        // ═══════════════════════════════════════════════════════════════

        ArchitectureEntry(
            id: "engine_stats_core",
            category: .pythonEngine,
            title: "Core Statistics (stats.py)",
            summary: "All statistical primitives: descriptive stats, hypothesis tests, effect sizes, survival analysis.",
            details: """
                refraction/core/stats.py is the single source of truth for all mathematical computation \
                in Refraction. It contains:

                Descriptive statistics: calc_mean, calc_sd, calc_sem, calc_error (SEM/SD/CI95), \
                descriptive_stats (returns n, mean, sd, sem, min, median, max).

                Hypothesis testing via _run_stats(): dispatches to the correct test based on group count, \
                test type (parametric/nonparametric/paired/permutation/one_sample), and applies posthoc \
                corrections. Returns list of (group_a, group_b, p_value, stars) tuples.

                P-value helpers: _p_to_stars converts p-values to asterisk notation (ns, *, **, ***, ****). \
                _apply_correction applies multiple comparisons corrections (Bonferroni, Holm-Bonferroni, \
                Sidak, Hochberg, Benjamini-Hochberg).

                Effect sizes: _cohens_d for pairwise effect size computation.

                Normality: check_normality runs Shapiro-Wilk on each group. normality_warning returns \
                a human-readable warning string if data is non-normal.

                Survival analysis: _km_curve computes Kaplan-Meier survival estimates with confidence \
                intervals and median survival.

                Two-way ANOVA: _twoway_anova for factorial designs.

                The module uses scipy.stats for all test implementations and numpy for array operations.
                """,
            relatedFiles: [
                "refraction/core/stats.py",
                "refraction/core/chart_helpers.py",
            ],
            methods: [
                MethodSignature(
                    signature: "_run_stats(groups, test_type, control, mc_correction, posthoc) -> list[tuple]",
                    description: "Run statistical tests on groups dict. Returns list of (group_a, group_b, p_value, stars)."
                ),
                MethodSignature(
                    signature: "calc_error(vals, error_type) -> (float, float)",
                    description: "Return (mean, error_bar_half_width) for SEM, SD, or CI95."
                ),
                MethodSignature(
                    signature: "_p_to_stars(p) -> str",
                    description: "Convert p-value to asterisk annotation: ns, *, **, ***, or ****."
                ),
                MethodSignature(
                    signature: "_apply_correction(raw_p, method) -> list[float]",
                    description: "Apply multiple comparisons correction (Bonferroni, Holm, Sidak, Hochberg, BH)."
                ),
                MethodSignature(
                    signature: "check_normality(groups) -> dict",
                    description: "Run Shapiro-Wilk test on each group. Returns {name: (stat, p, is_normal, warning)}."
                ),
                MethodSignature(
                    signature: "descriptive_stats(vals) -> dict",
                    description: "Return dict with n, mean, sd, sem, min, median, max for a numeric array."
                ),
                MethodSignature(
                    signature: "_cohens_d(group1, group2) -> float",
                    description: "Compute Cohen's d effect size between two groups."
                ),
                MethodSignature(
                    signature: "_km_curve(times, events) -> dict",
                    description: "Compute Kaplan-Meier survival curve with confidence intervals and median survival."
                ),
                MethodSignature(
                    signature: "recommend_test(groups, paired) -> dict",
                    description: "Recommend the best statistical test based on data characteristics."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "engine_analysis",
            category: .pythonEngine,
            title: "Analysis Engine (engine.py)",
            summary: "Central dispatch: routes chart types to dedicated analyzers or the generic fallback.",
            details: """
                refraction/analysis/engine.py contains the analyze() function, the main entry point \
                for all analysis. It receives a chart type, file path, and config dict, and returns \
                a plain dict with groups, comparisons, and metadata.

                Dispatch strategy:
                1. Check if chart_type exists in _DEDICATED_ANALYZERS dict.
                2. If yes, call the dedicated analyzer function with the config dict.
                3. If no, fall through to the generic column-as-groups analysis path.

                The _DEDICATED_ANALYZERS dict maps chart type keys to lazy-loaded analyzer functions. \
                Currently 18 chart types have dedicated analyzers. The remaining types (bar, \
                before_after, heatmap, etc.) use the generic fallback that treats each column as a group.

                The generic fallback reads the Excel file, treats row 0 as group names and subsequent \
                rows as values, computes descriptive statistics per group, and optionally runs \
                statistical tests. This works for simple column-based layouts but lacks chart-specific \
                logic.

                Each dedicated analyzer is lazily loaded via _lazy_load_analyzer() to avoid importing \
                all analyzers at startup. The analyzer receives the full config dict with excel_path \
                and _chart_type injected, and returns an AnalysisSpec object (with a .to_dict() method).
                """,
            relatedFiles: [
                "refraction/analysis/engine.py",
                "refraction/analysis/__init__.py",
            ],
            methods: [
                MethodSignature(
                    signature: "analyze(chart_type, excel_path, config) -> dict",
                    description: "Main entry point. Dispatches to dedicated analyzer or generic fallback."
                ),
                MethodSignature(
                    signature: "_lazy_load_analyzer(module_name, func_name) -> callable",
                    description: "Create a lazy loader that imports the analyzer function on first call."
                ),
                MethodSignature(
                    signature: "available_chart_types() -> list[str]",
                    description: "Return sorted list of all 29 supported chart type keys."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "engine_validators",
            category: .pythonEngine,
            title: "Data Validators",
            summary: "Validate that uploaded data matches the expected table type layout before analysis.",
            details: """
                refraction/core/validators.py contains validation functions for each table type. \
                Each validator receives a pandas DataFrame (read with header=None) and returns \
                a tuple of (errors: list[str], warnings: list[str]).

                Validators check for:
                - Correct number of columns for the chart type
                - Presence of numeric data where expected
                - Correct header structure (group names, series labels)
                - Survival data format (time/event pairs with 0/1 events)
                - Contingency table format (count data, proper labels)
                - Two-way ANOVA format (Factor_A, Factor_B, Value columns)

                The POST /validate-table endpoint maps table type strings to validators and returns \
                the validation results. This is called by the Swift app after upload to warn users \
                about data format issues before they attempt analysis.

                If no specific validator exists for a table type, the endpoint accepts the data \
                if it contains any numeric values.
                """,
            relatedFiles: [
                "refraction/core/validators.py",
                "refraction/server/api.py",
            ],
            methods: [
                MethodSignature(
                    signature: "validate_bar(df) -> (list[str], list[str])",
                    description: "Validate column/bar chart data: group names in row 0, numeric values below."
                ),
                MethodSignature(
                    signature: "validate_line(df) -> (list[str], list[str])",
                    description: "Validate XY/line data: X values in col 0, Y series in subsequent columns."
                ),
                MethodSignature(
                    signature: "validate_kaplan_meier(df) -> (list[str], list[str])",
                    description: "Validate survival data: paired time/event columns with 0/1 event indicators."
                ),
            ]
        ),

        // ═══════════════════════════════════════════════════════════════
        // SWIFT RENDERERS
        // ═══════════════════════════════════════════════════════════════

        ArchitectureEntry(
            id: "renderer_chart_canvas",
            category: .swiftRenderers,
            title: "ChartCanvasView",
            summary: "The main chart rendering view that reads ChartSpec and draws using Apple Charts framework.",
            details: """
                ChartCanvasView is a SwiftUI view in the RefractionRenderer Swift package that takes \
                a ChartSpec and renders the chart using Apple's Charts framework.

                It reads the spec's chart type, groups, stats, brackets, and layout information to \
                build the appropriate chart marks (BarMark, LineMark, PointMark, etc.). The view \
                also handles statistical annotation brackets above the chart.

                The RefractionRenderer package contains dedicated renderers for each chart type: \
                BarRenderer, LineRenderer, ScatterRenderer, BoxRenderer, ViolinRenderer, \
                HistogramRenderer, DotPlotRenderer, GroupedBarRenderer, StackedBarRenderer, \
                BeforeAfterRenderer, and KaplanMeierRenderer.

                Each renderer reads the ChartSpec and produces SwiftUI Chart content. The renderers \
                handle chart-specific layout like box plot whiskers, violin kernel density curves, \
                and Kaplan-Meier step functions.

                ChartOverlayView provides interactive overlay features like tooltips and hit regions \
                on top of the chart canvas.
                """,
            relatedFiles: [
                "RefractionApp/Refraction/Views/Chart/ChartCanvasView.swift",
                "RefractionApp/Refraction/Views/Chart/ChartOverlayView.swift",
                "RefractionRenderer/Sources/RefractionRenderer/BarRenderer.swift",
                "RefractionRenderer/Sources/RefractionRenderer/LineRenderer.swift",
                "RefractionRenderer/Sources/RefractionRenderer/ScatterRenderer.swift",
                "RefractionRenderer/Sources/RefractionRenderer/BoxRenderer.swift",
                "RefractionRenderer/Sources/RefractionRenderer/ViolinRenderer.swift",
            ],
            methods: []
        ),

        ArchitectureEntry(
            id: "renderer_chart_spec",
            category: .swiftRenderers,
            title: "ChartSpec (Data Model)",
            summary: "The JSON schema bridging Python engine output and SwiftUI chart rendering.",
            details: """
                ChartSpec is a Codable struct defined in the RefractionRenderer package. It represents \
                the complete specification for rendering a chart, decoded from the JSON response of \
                POST /render.

                Key properties:
                - chartType: the type of chart to render
                - groups: array of group objects, each with name, values (raw, mean, sem, sd, ci95, n), and color
                - stats: optional statistical test results with test_name, comparisons, and p_value
                - brackets: array of annotation brackets with left/right indices, label, and stacking order
                - layout: chart dimensions and spacing
                - title, xLabel, yLabel: axis labels
                - errorBars: error bar configuration (type, visible)

                The _to_chart_spec() function in api.py transforms the raw analyze() output into this \
                schema, mapping engine group dicts to the nested values structure and building bracket \
                arrays from comparison results.

                ChartSpec is designed to be renderer-agnostic: it contains all the data needed to draw \
                the chart but no rendering instructions. This allows the same spec to be rendered by \
                different backends.
                """,
            relatedFiles: [
                "RefractionRenderer/Sources/RefractionRenderer/ChartSpec.swift",
                "refraction/server/api.py",
            ],
            methods: []
        ),

        ArchitectureEntry(
            id: "renderer_render_styles",
            category: .swiftRenderers,
            title: "Render Styles",
            summary: "Four visual presets (Default, Prism, ggplot2, Matplotlib) that configure all visual properties.",
            details: """
                RenderStyle is a Swift enum with four cases that mimic popular plotting library aesthetics:

                Default: Clean style with light grid, Helvetica font, thin axis lines. L-shaped axes \
                (no frame), solid light gray major grid, ticks pointing outward.

                Prism: Matches GraphPad Prism look. Bold axes (1.5pt), no grid, no bar borders, \
                Arial font, larger font sizes. The classic scientific publication style.

                ggplot2: Matches R's ggplot2 default theme. Gray (#EBEBEB) plot background, white \
                grid lines, no visible axis lines, no tick marks, Helvetica font, slightly smaller sizes.

                Matplotlib: Matches Python's matplotlib defaults. Full frame around plot area, dashed \
                gray grid, thin bar borders, ticks pointing outward.

                Each style also defines a color palette: Prism uses the PRISM_PALETTE (10 colors), \
                ggplot2 uses hue_pal approximation, and Matplotlib uses the tab10 palette.

                Styles are applied via RenderStyle.apply(to:axes:) which sets all visual properties \
                on both FormatGraphSettings and FormatAxesSettings. User customizations made after \
                applying a preset are preserved until the next preset application.
                """,
            relatedFiles: [
                "RefractionApp/Refraction/Models/RenderStyle.swift",
            ],
            methods: [
                MethodSignature(
                    signature: "RenderStyle.apply(to graph: FormatGraphSettings, axes: FormatAxesSettings)",
                    description: "Apply all visual properties for this style preset to the given settings objects."
                ),
                MethodSignature(
                    signature: "RenderStyle.palette -> [String]",
                    description: "Return the 10-color hex palette for this style (e.g., PRISM_PALETTE, tab10)."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "renderer_hit_regions",
            category: .swiftRenderers,
            title: "Hit Regions & Interactivity",
            summary: "HitRegion enables click-to-inspect on chart elements like bars, points, and boxes.",
            details: """
                The HitRegion struct (in RefractionRenderer) defines clickable areas on the chart canvas. \
                Each rendered element (bar, point, box, line segment) can register a hit region with \
                metadata about what it represents (group name, value, index).

                When the user clicks on the chart, ChartOverlayView performs hit testing against \
                registered regions and shows a tooltip or inspector with the element's data.

                This system allows interactive exploration of chart data without re-querying the engine. \
                All data needed for tooltips is already present in the ChartSpec.
                """,
            relatedFiles: [
                "RefractionRenderer/Sources/RefractionRenderer/HitRegion.swift",
                "RefractionApp/Refraction/Views/Chart/ChartOverlayView.swift",
            ],
            methods: []
        ),

        // ═══════════════════════════════════════════════════════════════
        // MODELS
        // ═══════════════════════════════════════════════════════════════

        ArchitectureEntry(
            id: "model_experiment",
            category: .models,
            title: "Experiment",
            summary: "Top-level container owning DataTables, Graphs, and Analyses within a project.",
            details: """
                Experiment is an @Observable class that groups related data tables, graphs, and analyses. \
                It is the primary organizational unit in the project hierarchy.

                An experiment owns:
                - dataTables: [DataTable] — each with a TableType and optional file path
                - graphs: [Graph] — each linked to one DataTable by UUID
                - analyses: [Analysis] — each linked to one DataTable by UUID
                - label: display name
                - info: free-text metadata

                Key behaviors:
                - addGraph() rejects duplicate labels within the same experiment
                - removeDataTable() orphans linked graphs/analyses (they show "missing data table" in UI)
                - validChartTypes(for:) returns chart types valid for a specific data table
                - hasData indicates whether any data table has data loaded

                The experiment model does not interact with the engine directly; it is purely a \
                state container. The AppState coordinates between experiments and API calls.
                """,
            relatedFiles: [
                "RefractionApp/Refraction/Models/Experiment.swift",
            ],
            methods: [
                MethodSignature(
                    signature: "Experiment.addDataTable(type:label:) -> DataTable",
                    description: "Create and append a new data table with the specified type."
                ),
                MethodSignature(
                    signature: "Experiment.addGraph(chartType:dataTableID:label:) -> Graph?",
                    description: "Create a graph linked to a data table. Returns nil if label is duplicate."
                ),
                MethodSignature(
                    signature: "Experiment.dataTable(for graph: Graph) -> DataTable?",
                    description: "Find the DataTable referenced by a given graph."
                ),
                MethodSignature(
                    signature: "Experiment.allValidChartTypes -> [ChartType]",
                    description: "Union of valid chart types across all data tables in this experiment."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "model_data_table",
            category: .models,
            title: "DataTable",
            summary: "A typed data table with file path reference, constraining which charts can be created.",
            details: """
                DataTable is an @Observable class representing a single data table within an experiment. \
                Each table has a TableType that determines which chart types are valid for it.

                Properties:
                - id: UUID identifier
                - label: display name (e.g., "Column 1", "XY Data")
                - tableType: the data layout type (Column, XY, Grouped, etc.)
                - dataFilePath: server-side path to the uploaded file (set after POST /upload)
                - originalFileName: the user's original filename for display

                Computed properties:
                - hasData: true if dataFilePath is set and non-empty
                - availableChartTypes: chart types valid for this table's type

                DataTable does not store the actual data; it stores a reference to the server-side file. \
                The engine reads the file when analysis is requested. This keeps the Swift app lightweight \
                and avoids duplicating data in memory.
                """,
            relatedFiles: [
                "RefractionApp/Refraction/Models/DataTable.swift",
                "RefractionApp/Refraction/Models/TableType.swift",
            ],
            methods: [
                MethodSignature(
                    signature: "DataTable.hasData -> Bool",
                    description: "Whether data has been loaded (dataFilePath is set and non-empty)."
                ),
                MethodSignature(
                    signature: "DataTable.availableChartTypes -> [ChartType]",
                    description: "Chart types valid for this table's TableType."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "model_graph",
            category: .models,
            title: "Graph",
            summary: "A chart within an experiment: chart type, config, cached spec, and format settings.",
            details: """
                Graph is an @Observable class representing a single chart. It links to a DataTable \
                by UUID and holds all configuration and rendering state.

                Properties:
                - chartType: the type of chart (bar, scatter, violin, etc.)
                - chartConfig: ChartConfig with ~40 properties sent to the engine
                - chartSpec: ChartSpec? — cached result from the engine (nil until first render)
                - formatSettings: FormatGraphSettings for bar/line/point visual properties
                - formatAxesSettings: FormatAxesSettings for axis/grid/font properties
                - renderStyle: current RenderStyle preset (Default, Prism, ggplot2, Matplotlib)
                - isLoading: whether an analysis request is in flight
                - rawJSON: pretty-printed raw JSON for developer mode inspection
                - zoomLevel: canvas zoom (0.25x to 4.0x, default 1.0)

                The graph does not perform analysis itself. When the user triggers a render, the \
                containing view calls APIClient.analyze() with the graph's chartType and chartConfig, \
                then stores the returned ChartSpec.
                """,
            relatedFiles: [
                "RefractionApp/Refraction/Models/Graph.swift",
                "RefractionApp/Refraction/Models/ChartConfig.swift",
            ],
            methods: [
                MethodSignature(
                    signature: "Graph.applyRenderStyle(_ style: RenderStyle)",
                    description: "Apply a render style preset, updating formatSettings and formatAxesSettings."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "model_chart_config",
            category: .models,
            title: "ChartConfig",
            summary: "Observable model with ~40 properties organized by tab, serialized to the engine as a dict.",
            details: """
                ChartConfig is an @Observable class with properties organized by the config panel tabs:

                Data tab: excelPath, sheet (index).
                Labels tab: title, xlabel, ylabel.
                Style tab - error bars: errorType (SEM/SD/CI95), showPoints, jitter, pointSize, pointAlpha.
                Style tab - axes: axisStyle, tickDirection, minorTicks, spineWidth.
                Style tab - layout: figWidth, figHeight, fontSize, barWidth, lineWidth, markerStyle, markerSize.
                Style tab - colors: figBackground, gridStyle, alpha, capSize.
                Style tab - scale: yScale (linear/log), yMin, yMax, yTickInterval, xTickInterval.
                Style tab - reference line: refLineValue, refLineLabel.
                Stats tab: statsTest, posthoc, mcCorrection, control, showNs, showPValues, \
                showEffectSize, showTestName, showNormalityWarning, pThreshold, bracketStyle.

                The toDict() method serializes these into a flat dictionary that gets sent as the \
                "kw" field to POST /render. The /render endpoint maps certain Swift-style keys to \
                engine-style keys (e.g., "error" -> "error_type").
                """,
            relatedFiles: [
                "RefractionApp/Refraction/Models/ChartConfig.swift",
            ],
            methods: [
                MethodSignature(
                    signature: "ChartConfig.toDict() -> [String: Any]",
                    description: "Serialize all config properties into a dictionary for the API."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "model_analysis",
            category: .models,
            title: "Analysis",
            summary: "Statistical analysis results within an experiment, linked to a DataTable.",
            details: """
                Analysis is an @Observable class storing the results of a standalone statistical analysis. \
                It links to a DataTable by UUID and stores:

                - analysisType: string identifier (e.g., "unpaired_t", "anova", "kruskal_wallis")
                - statsResults: StatsResult? — decoded from POST /analyze-stats response
                - notes: free-text user notes about the analysis
                - rawJSON: raw JSON for debugging

                StatsResult contains descriptive statistics per group, normality test results, \
                pairwise comparisons with p-values and effect sizes, a summary string, and a \
                test recommendation.

                Analyses are displayed in ResultsSheetView with tables for descriptive statistics, \
                normality, and comparisons.
                """,
            relatedFiles: [
                "RefractionApp/Refraction/Models/Analysis.swift",
                "RefractionApp/Refraction/Views/Results/ResultsView.swift",
                "RefractionApp/Refraction/Views/Sheets/ResultsSheetView.swift",
            ],
            methods: []
        ),

        ArchitectureEntry(
            id: "model_app_state",
            category: .models,
            title: "AppState",
            summary: "Central @Observable state: experiments, selection tracking, undo, project save/load.",
            details: """
                AppState is the root observable object for the entire application. It is injected \
                into the environment at the top level and accessed by all views.

                State properties:
                - experiments: [Experiment] — all experiments in the project
                - activeExperimentID: UUID? — currently selected experiment
                - activeItemID: UUID? — currently selected item (data table, graph, or analysis)
                - activeItemKind: ItemKind? — type of selected item
                - developerMode: Bool — show raw JSON in the UI
                - projectFilePath: URL? — current project file path (nil = never saved)
                - hasUnsavedChanges: Bool — dirty flag

                Computed accessors:
                - activeExperiment: looks up the experiment by activeExperimentID
                - activeDataTable, activeGraph, activeAnalysis: look up the active item by kind and ID

                Operations:
                - newProject(): reset to empty state
                - openProjectFile(), saveProjectFile(): project I/O via file dialogs
                - loadProjectFromURL(): load a .refract file
                - removeDataTable/Graph/Analysis: deletion with ID

                AppState also manages the UndoManager for undo/redo support.
                """,
            relatedFiles: [
                "RefractionApp/Refraction/App/AppState.swift",
            ],
            methods: [
                MethodSignature(
                    signature: "AppState.newProject()",
                    description: "Reset all state to a new empty project."
                ),
                MethodSignature(
                    signature: "AppState.openProjectFile() async",
                    description: "Present a file picker and load the selected .refract file."
                ),
                MethodSignature(
                    signature: "AppState.saveProjectFile() async",
                    description: "Save the current project to a .refract file."
                ),
            ]
        ),

        // ═══════════════════════════════════════════════════════════════
        // API ENDPOINTS
        // ═══════════════════════════════════════════════════════════════

        ArchitectureEntry(
            id: "api_health",
            category: .apiEndpoints,
            title: "GET /health",
            summary: "Liveness check returning {\"status\": \"ok\"}.",
            details: """
                Simple health check endpoint used by the Swift app to verify the Python server is running \
                before making analysis requests. Returns {"status": "ok"} with HTTP 200.

                Called during app startup to wait for the server to become ready, and periodically \
                to detect if the server has crashed.
                """,
            relatedFiles: ["refraction/server/api.py"],
            methods: []
        ),

        ArchitectureEntry(
            id: "api_chart_types",
            category: .apiEndpoints,
            title: "GET /chart-types",
            summary: "List all 29 supported chart types with priority ordering.",
            details: """
                Returns a JSON object with two keys:
                - priority: ["bar", "grouped_bar", "line", "scatter"] — the most common chart types shown first
                - all: complete sorted list of all 29 chart type keys

                Used by the Swift app to populate the chart type picker when creating new graphs. \
                The priority list determines which types appear prominently.
                """,
            relatedFiles: ["refraction/server/api.py"],
            methods: []
        ),

        ArchitectureEntry(
            id: "api_analyze",
            category: .apiEndpoints,
            title: "POST /analyze",
            summary: "Run renderer-independent analysis on uploaded data (raw engine output).",
            details: """
                Accepts: {chart_type: string, excel_path: string, config: dict}

                Calls analyze() from the analysis engine and returns the raw result dict. \
                This is the lower-level endpoint that returns engine output without transformation \
                to the ChartSpec schema.

                Used for programmatic access to the analysis engine. The Swift app typically uses \
                /render instead, which wraps /analyze with ChartSpec transformation.

                Returns the engine result dict with ok, chart_type, groups, comparisons, title, etc.
                """,
            relatedFiles: [
                "refraction/server/api.py",
                "refraction/analysis/engine.py",
            ],
            methods: []
        ),

        ArchitectureEntry(
            id: "api_render",
            category: .apiEndpoints,
            title: "POST /render",
            summary: "Bridge endpoint for SwiftUI: analyze + transform to ChartSpec JSON schema.",
            details: """
                Accepts: {chart_type: string, kw: dict}  (kw contains excel_path and all config properties)

                This is the primary endpoint used by the Swift app. It:
                1. Extracts excel_path from kw
                2. Maps Swift config key names to engine key names
                3. Calls analyze(chart_type, excel_path, config)
                4. Transforms the result via _to_chart_spec() into the ChartSpec JSON schema
                5. Wraps in {"ok": true, "spec": {...}}

                If kw contains _debug: true, the response includes a _trace array showing \
                the analysis steps (analyzer used, groups found, comparisons computed).

                The _to_chart_spec() transformation handles:
                - Nesting group values into {raw, mean, sem, sd, ci95, n} structure
                - Building bracket arrays from comparisons for statistical annotations
                - Assigning colors from the PRISM_PALETTE
                - Setting error bar configuration
                - Sanitizing NaN/Inf values to null for JSON safety
                """,
            relatedFiles: [
                "refraction/server/api.py",
                "RefractionApp/Refraction/Services/APIClient.swift",
            ],
            methods: [
                MethodSignature(
                    signature: "_to_chart_spec(result: dict, config: dict) -> dict",
                    description: "Transform analyze() output into the ChartSpec JSON schema for Swift decoding."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "api_upload",
            category: .apiEndpoints,
            title: "POST /upload",
            summary: "Accept .xlsx/.xls/.csv file upload, store in temp dir, return server-side path.",
            details: """
                Accepts: multipart form data with a single file field.

                Validates file extension (.xlsx, .xls, .csv) and size (max 10 MB). Saves the file \
                with a UUID-based name in $TMPDIR/refraction-uploads/. Returns {"ok": true, "path": \
                "...", "filename": "original.xlsx"}.

                The returned path is used by all subsequent analysis endpoints. Files are cleaned up \
                on server exit via an atexit handler.
                """,
            relatedFiles: ["refraction/server/api.py"],
            methods: []
        ),

        ArchitectureEntry(
            id: "api_sheet_list",
            category: .apiEndpoints,
            title: "POST /sheet-list",
            summary: "Return list of sheet names in an Excel file.",
            details: """
                Accepts: {excel_path: string}

                For Excel files, reads sheet names via openpyxl in read-only mode. \
                For CSV files, returns ["Sheet1"]. Used by the data tab to let users \
                select which sheet to analyze when the file contains multiple sheets.
                """,
            relatedFiles: ["refraction/server/api.py"],
            methods: []
        ),

        ArchitectureEntry(
            id: "api_validate_table",
            category: .apiEndpoints,
            title: "POST /validate-table",
            summary: "Validate that data matches the expected table type layout.",
            details: """
                Accepts: {excel_path: string, table_type: string, sheet: int|string}

                Maps table_type to the appropriate validator function (validate_bar, validate_line, \
                validate_grouped_bar, etc.) and runs it against the data.

                Returns: {ok: true, valid: bool, errors: [...], warnings: [...], shape: [rows, cols]}

                If no specific validator exists for the table type, accepts the data if it contains \
                numeric values and returns a warning. Validators check column count, header structure, \
                and data types specific to each layout convention.
                """,
            relatedFiles: [
                "refraction/server/api.py",
                "refraction/core/validators.py",
            ],
            methods: []
        ),

        ArchitectureEntry(
            id: "api_data_preview",
            category: .apiEndpoints,
            title: "POST /data-preview",
            summary: "Return raw contents of an Excel/CSV file as JSON for read-only display.",
            details: """
                Accepts: {excel_path: string, sheet: int|string}

                Reads up to 200 rows of data and returns {ok: true, columns: [...], rows: [[...]], \
                shape: [rows, cols]}. NaN values are replaced with null.

                Used by the DataTableView to show a read-only preview of the uploaded data \
                in a spreadsheet-like grid.
                """,
            relatedFiles: ["refraction/server/api.py"],
            methods: []
        ),

        ArchitectureEntry(
            id: "api_recommend_test",
            category: .apiEndpoints,
            title: "POST /recommend-test",
            summary: "Analyze data and recommend the best statistical test.",
            details: """
                Accepts: {excel_path: string, sheet: int|string, paired: bool}

                Reads the data, extracts numeric groups, runs normality tests and Levene's test \
                for equal variance, then calls recommend_test() to suggest the best statistical test.

                Returns diagnostic checks (nGroups, paired, allNormal, equalVariance, normality per group) \
                and the recommendation (test name, label, posthoc, justification).

                This endpoint powers the Stats Wiki dialog's decision tree and recommendation feature.
                """,
            relatedFiles: [
                "refraction/server/api.py",
                "refraction/core/stats.py",
            ],
            methods: []
        ),

        ArchitectureEntry(
            id: "api_analyze_stats",
            category: .apiEndpoints,
            title: "POST /analyze-stats",
            summary: "Run standalone statistical analysis: descriptive stats, normality, comparisons, effect sizes.",
            details: """
                Accepts: {excel_path: string, analysis_type: string, sheet: int|string, \
                paired: bool, mc_correction: string, posthoc: string, control: string}

                This is the most comprehensive statistics endpoint. It:
                1. Reads data and extracts numeric groups from columns
                2. Computes descriptive statistics (n, mean, sd, sem, median, ci95) per group
                3. Runs Shapiro-Wilk normality tests per group
                4. Maps analysis_type to the engine's test_type (parametric, nonparametric, paired, etc.)
                5. Runs the statistical test via _run_stats()
                6. Computes Cohen's d effect sizes for pairwise comparisons
                7. Generates a summary string (e.g., "One-way ANOVA: F(2,27) = 12.34, p = 0.0001")
                8. Gets a test recommendation

                Returns: {descriptive, normality, comparisons, summary, recommendation, analysis_label}

                Used by the Analyze Data dialog to create Analysis objects with full statistical results.
                """,
            relatedFiles: [
                "refraction/server/api.py",
                "refraction/core/stats.py",
            ],
            methods: []
        ),

        ArchitectureEntry(
            id: "api_render_latex",
            category: .apiEndpoints,
            title: "POST /render-latex",
            summary: "Render a LaTeX formula to PNG using matplotlib's mathtext engine.",
            details: """
                Accepts: {latex: string, dpi: int, fontsize: int}

                Uses matplotlib's mathtext renderer to convert LaTeX formulas into transparent PNG images. \
                Results are cached in memory by (latex, dpi, fontsize) key for repeated requests.

                Returns: {ok: true, png_base64: "..."} — the PNG image as a base64-encoded string.

                Used by LaTeXView in the Stats Wiki to render mathematical formulas (hypotheses, \
                test statistics) inline in the UI. The Swift app decodes the base64 PNG and displays \
                it as an NSImage.
                """,
            relatedFiles: [
                "refraction/server/api.py",
                "RefractionApp/Refraction/Views/LaTeXView.swift",
            ],
            methods: []
        ),

        ArchitectureEntry(
            id: "api_curve_models",
            category: .apiEndpoints,
            title: "GET /curve-models",
            summary: "List all available curve fitting models organized by category.",
            details: """
                Returns: {ok: true, models: {category: [model_info...]}, total: int}

                Lists all curve fitting models from refraction/analysis/curve_models.py, grouped \
                by category (e.g., Polynomial, Exponential, Sigmoidal, etc.). Each model includes \
                its name, equation, parameter descriptions, and default initial values.

                Used by the curve fit configuration UI to let users select a model for fitting.
                """,
            relatedFiles: [
                "refraction/server/api.py",
                "refraction/analysis/curve_models.py",
            ],
            methods: []
        ),

        ArchitectureEntry(
            id: "api_curve_fit",
            category: .apiEndpoints,
            title: "POST /curve-fit",
            summary: "Fit a curve model to X/Y data points.",
            details: """
                Accepts: {x: [float], y: [float], model_name: string, initial_params: [float]?}

                Performs nonlinear curve fitting using scipy.optimize.curve_fit. Returns the fitted \
                parameters, R-squared, residuals, and predicted Y values for the fitted curve.

                The initial_params are optional; if not provided, the model's default initial guesses \
                are used. Raises ValueError if the model name is not recognized.
                """,
            relatedFiles: [
                "refraction/server/api.py",
                "refraction/analysis/curve_fit.py",
                "refraction/analysis/curve_models.py",
            ],
            methods: []
        ),

        ArchitectureEntry(
            id: "api_transforms",
            category: .apiEndpoints,
            title: "GET /transforms & POST /transform",
            summary: "List and apply column transformations (log, normalize, z-score, etc.).",
            details: """
                GET /transforms returns: {ok: true, transforms: [...], total: int}
                Lists all available column transformations with names and descriptions.

                POST /transform accepts: {data_path: string, column: string|int, operation: string, \
                params: dict, sheet: int|string}

                Applies a transformation to a column in the data file and writes the result to a new \
                temp Excel file. Returns the path to the new file and the new column name \
                (formatted as "original_operation").

                Available transforms include: log, log2, log10, ln, sqrt, square, reciprocal, \
                normalize, z_score, rank, percentile, cumsum, diff, and more.
                """,
            relatedFiles: [
                "refraction/server/api.py",
                "refraction/analysis/transforms.py",
            ],
            methods: []
        ),

        ArchitectureEntry(
            id: "api_project_save",
            category: .apiEndpoints,
            title: "POST /project/save-refract",
            summary: "Save the current project as a .refract ZIP file with embedded data.",
            details: """
                Accepts: {output_path: string, project: dict}

                Saves the project state as a .refract archive (ZIP format) containing:
                1. manifest.json — format version (v3), app version, creation timestamp
                2. project.json — sanitized project state with dataRef pointers (no absolute paths)
                3. data/ — embedded data files converted to CSV for portability
                4. charts/ — chart configs and format settings per graph
                5. results/ — analysis results per results sheet

                Security: validates that output_path is within the user's home directory and \
                rejects path traversal (.. components). Parent directory must exist.

                Data embedding: Excel files are read via pandas and re-saved as CSV for cross-platform \
                portability. Absolute file paths are stripped and replaced with dataRef relative paths.
                """,
            relatedFiles: [
                "refraction/server/api.py",
            ],
            methods: []
        ),

        ArchitectureEntry(
            id: "api_project_load",
            category: .apiEndpoints,
            title: "POST /project/load",
            summary: "Upload and load a .refract project file (format v2 or v3).",
            details: """
                Accepts: multipart form data with a .refract file.

                Detects the format version from the manifest.json inside the ZIP:
                - Format v3 (current): uses _load_refract_v3() which extracts embedded CSV data to \
                  the uploads temp directory and restores dataFilePath pointers in the project dict.
                - Format v2 (legacy): uses the project_v2 module's load_project().

                Returns: {ok: true, project: dict} with the full project state including restored \
                data file paths.
                """,
            relatedFiles: [
                "refraction/server/api.py",
                "refraction/io/project.py",
            ],
            methods: []
        ),

        ArchitectureEntry(
            id: "api_analyze_layout",
            category: .apiEndpoints,
            title: "POST /analyze-layout",
            summary: "Analyze a multi-panel layout for publication-quality figure export.",
            details: """
                Accepts: {panels: [dict], title: string, export_width_mm: float, \
                export_height_mm: float, gap_px: int, panel_labels: bool}

                Computes layout positions for multiple chart panels arranged in a grid \
                for publication export. Each panel specifies its chart type, data, and config.

                Used for creating multi-panel figures (e.g., Figure 1A, 1B, 1C) common in \
                scientific publications. Panel labels (A, B, C...) can be automatically added.
                """,
            relatedFiles: [
                "refraction/server/api.py",
                "refraction/analysis/layout.py",
            ],
            methods: []
        ),

        // ═══════════════════════════════════════════════════════════════
        // ANALYSIS PIPELINE
        // ═══════════════════════════════════════════════════════════════

        ArchitectureEntry(
            id: "analyzer_xy",
            category: .analysisPipeline,
            title: "XY Analyzer",
            summary: "Handles scatter, line, area chart, curve fit, and bubble charts from XY data.",
            details: """
                The XY analyzer (refraction/analysis/xy.py) processes data with X values in the first \
                column and Y series in subsequent columns. It handles:

                - scatter: individual data points with optional trend lines
                - line: connected data points with optional error bars for replicate columns
                - area_chart: filled area under line series
                - curve_fit: nonlinear regression with model fitting
                - bubble: scatter with a third column controlling point size

                The analyzer detects whether Y columns are replicates (same header prefix) or \
                separate series. For replicates, it computes mean and error bars. For separate \
                series, each column becomes its own trace.

                Registered in _DEDICATED_ANALYZERS for: scatter, line, area_chart, curve_fit, bubble.
                """,
            relatedFiles: [
                "refraction/analysis/xy.py",
                "refraction/analysis/engine.py",
            ],
            methods: [
                MethodSignature(
                    signature: "analyze_xy(config: dict) -> AnalysisSpec",
                    description: "Analyze XY data for scatter, line, area, curve fit, or bubble charts."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "analyzer_box",
            category: .analysisPipeline,
            title: "Box Plot Analyzer",
            summary: "Dedicated box plot analysis with quartiles, whiskers, outliers, and optional stats.",
            details: """
                The box analyzer (refraction/analysis/box.py) computes the full set of box plot \
                statistics for each group:

                - Median (Q2), Q1 (25th percentile), Q3 (75th percentile)
                - IQR (interquartile range)
                - Whiskers: Q1 - 1.5*IQR and Q3 + 1.5*IQR (clamped to data range)
                - Outliers: points outside the whisker range
                - Individual data points for jittered overlay

                Also computes descriptive statistics (mean, SD, SEM) and runs optional statistical \
                tests (parametric, nonparametric, paired) with multiple comparisons correction.

                Registered in _DEDICATED_ANALYZERS for: box.
                """,
            relatedFiles: [
                "refraction/analysis/box.py",
            ],
            methods: [
                MethodSignature(
                    signature: "analyze_box(config: dict) -> AnalysisSpec",
                    description: "Analyze column data for box plots with quartiles, whiskers, and outliers."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "analyzer_violin",
            category: .analysisPipeline,
            title: "Violin Plot Analyzer",
            summary: "Kernel density estimation for violin shapes plus box plot statistics.",
            details: """
                The violin analyzer (refraction/analysis/violin.py) computes:

                - Kernel density estimate (KDE) for each group using scipy's gaussian_kde
                - Box plot statistics (median, Q1, Q3, whiskers)
                - Individual data points for optional strip overlay
                - Descriptive statistics and optional statistical tests

                The KDE points define the shape of the violin. The bandwidth is automatically \
                selected by scipy. The density values are normalized so violins are comparable \
                across groups.

                Registered in _DEDICATED_ANALYZERS for: violin.
                """,
            relatedFiles: [
                "refraction/analysis/violin.py",
            ],
            methods: [
                MethodSignature(
                    signature: "analyze_violin(config: dict) -> AnalysisSpec",
                    description: "Analyze column data for violin plots with KDE density curves."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "analyzer_histogram",
            category: .analysisPipeline,
            title: "Histogram Analyzer",
            summary: "Binning and frequency computation for histogram charts.",
            details: """
                The histogram analyzer (refraction/analysis/histogram.py) computes:

                - Optimal bin count using numpy's auto binning strategy
                - Bin edges and frequencies for each group
                - Optional density normalization (frequency or probability density)
                - Descriptive statistics per group

                The analyzer supports overlaid histograms (multiple groups on one axis) \
                and stacked histograms depending on configuration.

                Registered in _DEDICATED_ANALYZERS for: histogram.
                """,
            relatedFiles: [
                "refraction/analysis/histogram.py",
            ],
            methods: [
                MethodSignature(
                    signature: "analyze_histogram(config: dict) -> AnalysisSpec",
                    description: "Analyze column data for histograms with automatic binning."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "analyzer_grouped_bar",
            category: .analysisPipeline,
            title: "Grouped & Stacked Bar Analyzer",
            summary: "Two-factor bar charts with categories and subgroups.",
            details: """
                The grouped bar analyzer (refraction/analysis/grouped_bar.py) handles both \
                grouped bar and stacked bar charts:

                - Reads data with categories in row 0, subgroup names in row 1, values below
                - Computes mean and error for each category-subgroup combination
                - Supports statistical comparisons within categories or across subgroups
                - For stacked bars, computes cumulative values for stacking order

                This analyzer is shared between grouped_bar and stacked_bar chart types \
                since they use the same data layout but different visual representations.

                Registered in _DEDICATED_ANALYZERS for: grouped_bar, stacked_bar.
                """,
            relatedFiles: [
                "refraction/analysis/grouped_bar.py",
            ],
            methods: [
                MethodSignature(
                    signature: "analyze_grouped_bar(config: dict) -> AnalysisSpec",
                    description: "Analyze grouped data for grouped bar or stacked bar charts."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "analyzer_kaplan_meier",
            category: .analysisPipeline,
            title: "Kaplan-Meier (Survival) Analyzer",
            summary: "Survival curve computation with log-rank test and median survival.",
            details: """
                The Kaplan-Meier analyzer (refraction/analysis/kaplan_meier.py) processes \
                time-to-event survival data:

                - Reads paired time/event columns (each group has 2 columns)
                - Event column uses 0 = censored, 1 = event occurred
                - Computes step-function survival probabilities using the KM estimator
                - Calculates confidence intervals (Greenwood's formula)
                - Computes median survival time for each group
                - Runs log-rank test for group comparison

                The output includes step coordinates for drawing the characteristic \
                staircase survival curve, plus censoring tick marks.

                Registered in _DEDICATED_ANALYZERS for: kaplan_meier.
                """,
            relatedFiles: [
                "refraction/analysis/kaplan_meier.py",
                "refraction/core/stats.py",
            ],
            methods: [
                MethodSignature(
                    signature: "analyze_kaplan_meier(config: dict) -> AnalysisSpec",
                    description: "Analyze survival data for Kaplan-Meier curves with log-rank test."
                ),
                MethodSignature(
                    signature: "_km_curve(times, events) -> dict",
                    description: "Core KM computation: survival probabilities, CI, median survival."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "analyzer_two_way_anova",
            category: .analysisPipeline,
            title: "Two-Way ANOVA Analyzer",
            summary: "Factorial design analysis with main effects and interaction.",
            details: """
                The two-way ANOVA analyzer (refraction/analysis/two_way_anova.py) processes \
                data with two categorical factors:

                - Reads data with Factor_A, Factor_B, Value columns
                - Computes Type II sum of squares ANOVA
                - Reports main effects for each factor and interaction effect
                - Computes effect sizes (eta-squared)
                - Generates cell means for interaction plots

                This is distinct from one-way ANOVA which is handled by the generic analysis path.

                Registered in _DEDICATED_ANALYZERS for: two_way_anova.
                """,
            relatedFiles: [
                "refraction/analysis/two_way_anova.py",
                "refraction/core/stats.py",
            ],
            methods: [
                MethodSignature(
                    signature: "analyze_two_way_anova(config: dict) -> AnalysisSpec",
                    description: "Analyze factorial data for two-way ANOVA with interaction."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "analyzer_contingency",
            category: .analysisPipeline,
            title: "Contingency Table Analyzer",
            summary: "Chi-square test of independence and Fisher's exact test for categorical data.",
            details: """
                The contingency analyzer (refraction/analysis/contingency.py) processes \
                count data in a contingency table layout:

                - Reads data with outcome labels in row 0, group names in column 0, counts in cells
                - Runs chi-square test of independence
                - For 2x2 tables, also runs Fisher's exact test
                - Computes Cramer's V effect size
                - Reports expected counts for each cell

                Registered in _DEDICATED_ANALYZERS for: contingency.
                """,
            relatedFiles: [
                "refraction/analysis/contingency.py",
            ],
            methods: [
                MethodSignature(
                    signature: "analyze_contingency(config: dict) -> AnalysisSpec",
                    description: "Analyze contingency table with chi-square and Fisher's exact tests."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "analyzer_other",
            category: .analysisPipeline,
            title: "Other Dedicated Analyzers",
            summary: "Dot plot, raincloud, Bland-Altman, forest plot, chi-square GoF analyzers.",
            details: """
                Additional dedicated analyzers, each handling a specific chart type:

                Dot Plot (dot_plot.py): Similar to bar chart but renders individual points. \
                Computes means, error bars, and jittered point positions.

                Raincloud (raincloud.py): Combines a half-violin (KDE), box plot, and individual \
                points in a layered display. Computes all three components.

                Bland-Altman (bland_altman.py): Paired comparison method. Computes the mean of \
                two methods vs. their difference, bias (mean difference), and limits of agreement \
                (mean +/- 1.96 SD). Used for method comparison studies.

                Forest Plot (forest_plot.py): Meta-analysis display. Reads study name, effect size, \
                and confidence interval columns. Computes the summary effect with diamond marker.

                Chi-Square GoF (chi_square_gof.py): Goodness-of-fit test comparing observed frequencies \
                to expected distribution. Reads observed and optional expected count columns.
                """,
            relatedFiles: [
                "refraction/analysis/dot_plot.py",
                "refraction/analysis/raincloud.py",
                "refraction/analysis/bland_altman.py",
                "refraction/analysis/forest_plot.py",
                "refraction/analysis/chi_square_gof.py",
            ],
            methods: [
                MethodSignature(
                    signature: "analyze_dot_plot(config: dict) -> AnalysisSpec",
                    description: "Analyze column data for dot plots with means and error bars."
                ),
                MethodSignature(
                    signature: "analyze_raincloud(config: dict) -> AnalysisSpec",
                    description: "Analyze for raincloud plots: half-violin + box + strip."
                ),
                MethodSignature(
                    signature: "analyze_bland_altman(config: dict) -> AnalysisSpec",
                    description: "Analyze paired data for Bland-Altman agreement plots."
                ),
                MethodSignature(
                    signature: "analyze_forest_plot(config: dict) -> AnalysisSpec",
                    description: "Analyze meta-analysis data for forest plots."
                ),
                MethodSignature(
                    signature: "analyze_chi_square_gof(config: dict) -> AnalysisSpec",
                    description: "Analyze observed vs expected frequencies for chi-square GoF."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "analyzer_generic",
            category: .analysisPipeline,
            title: "Generic Analysis Path",
            summary: "Fallback for chart types without dedicated analyzers: treats columns as groups.",
            details: """
                When a chart type is not registered in _DEDICATED_ANALYZERS, the engine falls through \
                to the generic analysis path in engine.py. This path:

                1. Reads the Excel file and treats row 0 as group names
                2. Treats subsequent rows as numeric values for each group
                3. Computes descriptive statistics (mean, median, SD, SEM, CI95) per group
                4. Assigns colors from the PRISM_PALETTE
                5. Optionally runs statistical tests via _run_stats()
                6. Returns the standard {ok, chart_type, groups, comparisons} dict

                This generic path works for simple column-based layouts (bar, before_after, heatmap, \
                subcolumn_scatter, etc.) but does not handle chart-specific data layouts.

                The goal is to eventually give every chart type a dedicated analyzer. The generic \
                path is considered tech debt.
                """,
            relatedFiles: [
                "refraction/analysis/engine.py",
            ],
            methods: []
        ),

        ArchitectureEntry(
            id: "pipeline_stats_annotator",
            category: .analysisPipeline,
            title: "Stats Annotator",
            summary: "Shared helpers for building statistical annotation brackets from comparison results.",
            details: """
                refraction/analysis/stats_annotator.py provides shared utilities used by dedicated \
                analyzers to generate statistical annotation data:

                - Build comparison results from _run_stats() output
                - Format bracket annotations with p-value labels or stars
                - Handle bracket stacking order for multiple comparisons
                - Apply multiple comparisons corrections

                This module is imported by analyzers that need to add statistical annotations \
                to their output (box, violin, dot_plot, bar, etc.).
                """,
            relatedFiles: [
                "refraction/analysis/stats_annotator.py",
            ],
            methods: []
        ),

        // ═══════════════════════════════════════════════════════════════
        // FILE FORMATS
        // ═══════════════════════════════════════════════════════════════

        ArchitectureEntry(
            id: "format_refract",
            category: .fileFormats,
            title: ".refract Project File",
            summary: "ZIP archive containing manifest, project state, embedded data, charts, and results.",
            details: """
                The .refract file format is a ZIP archive used to save and load entire projects. \
                Format version 3 (current) contains:

                manifest.json:
                - format_version: 3
                - app_version: version string
                - created: Unix timestamp
                - created_iso: ISO 8601 timestamp

                project.json:
                - Full project state (experiments, data tables, graphs, analyses)
                - Absolute file paths stripped and replaced with dataRef pointers
                - Graph configs and format settings embedded

                data/ directory:
                - Embedded data files converted to CSV for portability
                - Named as table_0.csv, table_1.csv, etc.
                - Original Excel files are read by pandas and re-saved as CSV

                charts/ directory:
                - Chart configs and format settings per graph
                - Named as table_0_sheet_0.json, etc.

                results/ directory:
                - Statistical analysis results per analysis
                - Named as table_0_sheet_0.json, etc.

                On load, embedded CSV files are extracted to the temp uploads directory and \
                dataFilePath pointers are restored so the engine can access them.

                Format v2 (legacy) uses a different structure via refraction/io/project_v2.py \
                and is auto-detected on load.
                """,
            relatedFiles: [
                "refraction/server/api.py",
                "refraction/io/project.py",
            ],
            methods: []
        ),

        ArchitectureEntry(
            id: "format_excel_layouts",
            category: .fileFormats,
            title: "Excel Data Layouts",
            summary: "Standard data layouts for each chart type, following GraphPad Prism conventions.",
            details: """
                Each chart type expects a specific data layout in the Excel/CSV file:

                Bar/Box/Violin/Dot/Histogram (Column type):
                - Row 0: Group names (e.g., "Control", "Drug A", "Drug B")
                - Rows 1+: Numeric values per group

                Line/Scatter/Curve Fit (XY type):
                - Row 0: X-label in col 0, series names in cols 1+
                - Rows 1+: X value in col 0, Y replicates in cols 1+

                Grouped Bar / Stacked Bar (Grouped type):
                - Row 0: Category names
                - Row 1: Subgroup names
                - Rows 2+: Values

                Kaplan-Meier (Survival type):
                - Each group spans 2 columns: Time, Event
                - Row 0: Group names
                - Rows 1+: time value, 0 (censored) or 1 (event)

                Two-Way ANOVA (Two-Way type):
                - Columns: Factor_A, Factor_B, Value
                - One row per observation

                Contingency:
                - Row 0: blank cell + outcome labels
                - Rows 1+: Group name + counts

                Forest Plot (Meta type):
                - Columns: Study, Effect, Lower CI, Upper CI

                Bland-Altman (Comparison type):
                - Columns: Method A, Method B
                - Rows: paired measurements
                """,
            relatedFiles: [
                "refraction/core/validators.py",
                "refraction/analysis/engine.py",
            ],
            methods: []
        ),

        ArchitectureEntry(
            id: "format_chart_spec_json",
            category: .fileFormats,
            title: "ChartSpec JSON Schema",
            summary: "The JSON contract between the Python engine and Swift renderer.",
            details: """
                The ChartSpec JSON schema is the core data contract. The Python /render endpoint \
                produces it, and the Swift ChartSpec struct decodes it.

                Top-level structure:
                {
                  "chartType": "bar",
                  "groups": [{
                    "name": "Control",
                    "values": {"raw": [...], "mean": 5.0, "sem": 0.42, "sd": 1.2, "ci95": 0.96, "n": 8},
                    "color": "#E8453C"
                  }],
                  "stats": {
                    "test_name": "parametric",
                    "comparisons": [{
                      "group_1": "Control", "group_2": "Drug A",
                      "p_value": 0.003, "significant": true, "label": "**"
                    }]
                  },
                  "brackets": [{
                    "left_index": 0, "right_index": 1,
                    "label": "**", "stacking_order": 0
                  }],
                  "errorBars": {"type": "sem", "visible": true},
                  "layout": {"width": 5.0, "height": 5.0},
                  "title": "My Chart",
                  "xLabel": "", "yLabel": ""
                }

                Key design decisions:
                - Values are nested ({raw, mean, sem, sd, ci95, n}) rather than flat, so the \
                  renderer can access any statistic without re-computation
                - Brackets are separate from comparisons, with explicit indices into the groups array
                - Colors are pre-assigned by the engine from the PRISM_PALETTE
                - NaN/Inf values are sanitized to null before JSON encoding
                """,
            relatedFiles: [
                "RefractionRenderer/Sources/RefractionRenderer/ChartSpec.swift",
                "refraction/server/api.py",
            ],
            methods: []
        ),

        ArchitectureEntry(
            id: "format_export",
            category: .fileFormats,
            title: "Chart Export Formats",
            summary: "Export charts as PNG, SVG, or PDF with journal-specific presets (Nature, Science, Cell).",
            details: """
                The ExportChartDialog allows users to export charts in multiple formats:

                - PNG: rasterized at configurable DPI (72, 150, 300, 600) via ImageRenderer
                - SVG: vector format (planned)
                - PDF: vector format (planned)

                Journal presets configure export dimensions and DPI to match publication requirements:
                - Nature: 89mm single column or 183mm double column, 300 DPI minimum
                - Science: 9cm single column or 18cm double column, 300 DPI
                - Cell: standard figure dimensions

                The export presets are defined in refraction/io/export.py on the Python side \
                and in ExportChartDialog.swift on the Swift side.

                Copy to clipboard is also supported via the toolbar Copy button, which renders \
                the chart at 2x resolution and copies the NSImage to the system pasteboard.
                """,
            relatedFiles: [
                "RefractionApp/Refraction/Views/ExportChartDialog.swift",
                "refraction/io/export.py",
            ],
            methods: []
        ),

        // ═══════════════════════════════════════════════════════════════
        // SERVICES (extra models/services entries)
        // ═══════════════════════════════════════════════════════════════

        ArchitectureEntry(
            id: "service_api_client",
            category: .models,
            title: "APIClient (Service)",
            summary: "Thread-safe actor singleton for all HTTP communication with the Python backend.",
            details: """
                APIClient is a Swift actor that manages all HTTP requests to the FastAPI server \
                on 127.0.0.1:7331. It uses URLSession with configured timeouts:
                - Request timeout: 30 seconds
                - Resource timeout: 60 seconds

                Key methods:
                - analyze(): sends POST /render and decodes ChartSpec
                - analyzeWithRawJSON(): same but also returns pretty-printed raw JSON for debug mode
                - health(): sends GET /health
                - uploadFile(): sends POST /upload with multipart form data
                - recommendTest(): sends POST /recommend-test
                - analyzeStats(): sends POST /analyze-stats

                All methods are async and throw on network errors or server errors. The actor \
                isolation ensures thread safety for concurrent requests.
                """,
            relatedFiles: [
                "RefractionApp/Refraction/Services/APIClient.swift",
            ],
            methods: [
                MethodSignature(
                    signature: "APIClient.analyze(chartType:config:) async throws -> ChartSpec",
                    description: "Send render request, decode ChartSpec response."
                ),
                MethodSignature(
                    signature: "APIClient.analyzeWithRawJSON(chartType:config:debug:) async throws -> (ChartSpec, String)",
                    description: "Render with raw JSON for developer mode inspection."
                ),
                MethodSignature(
                    signature: "APIClient.uploadFile(url:) async throws -> UploadResponse",
                    description: "Upload a data file to the server."
                ),
                MethodSignature(
                    signature: "APIClient.recommendTest(excelPath:) async throws -> RecommendTestResponse",
                    description: "Get statistical test recommendation for the data."
                ),
            ]
        ),

        ArchitectureEntry(
            id: "service_debug_log",
            category: .models,
            title: "DebugLog (Service)",
            summary: "Centralized debug logger capturing API calls, app events, and engine traces.",
            details: """
                DebugLog is an @Observable singleton that captures timestamped log entries for \
                display in the DebugConsoleView. Entry types include:

                - REQ: outgoing HTTP request (method, path, body summary)
                - RES: incoming HTTP response (status, duration, body preview)
                - ERR: errors (network, server, decoding)
                - APP: app-level events (undo, copy, style change)
                - ENG: engine trace lines (when _debug mode is on)

                Each entry includes a timestamp (HH:mm:ss.SSS), method string, summary, \
                full detail text, optional duration in milliseconds, and error flag.

                The debug console is toggled via AppState.developerMode and shows a scrollable \
                list of log entries with syntax highlighting and filtering.
                """,
            relatedFiles: [
                "RefractionApp/Refraction/Services/DebugLog.swift",
                "RefractionApp/Refraction/Views/DebugConsoleView.swift",
            ],
            methods: [
                MethodSignature(
                    signature: "DebugLog.shared",
                    description: "Singleton instance for centralized logging."
                ),
                MethodSignature(
                    signature: "DebugLog.logAppEvent(_:detail:)",
                    description: "Log an app-level event (e.g., undo, copy, style change)."
                ),
            ]
        ),
    ]
}
