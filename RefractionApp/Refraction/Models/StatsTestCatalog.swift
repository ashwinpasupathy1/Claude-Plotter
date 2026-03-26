// StatsTestCatalog.swift — Textbook-level mathematical descriptions
// for every statistical test in the Stats Wiki.
//
// ─── Formula Markup Schema ────────────────────────────────────────
//
// The `hypotheses` and `testStatistic` fields are rendered by
// `formulaText()` in StatsTestDetailDialog.swift, which recognises
// three line types:
//
//   1. $...$   — LaTeX formula rendered as an image via the Python
//                engine. Use for ALL mathematical expressions:
//                fractions, subscripts, Greek letters, equalities,
//                inequalities, etc.
//
//                Examples:
//                  $H_0: \mu_1 = \mu_2$
//                  $t = \frac{\bar{x}_1 - \bar{x}_2}{s_p \sqrt{\frac{1}{n_1} + \frac{1}{n_2}}}$
//
//   2. #...    — Explanatory text rendered in italic. Use for
//                definitions and "where" clauses.
//
//                Examples:
//                  # where s_p is the pooled standard deviation.
//                  # with df = n₁ + n₂ - 2 degrees of freedom.
//
//   3. Plain   — Monospaced text. Use for procedural descriptions
//                and non-mathematical content.
//
//                Examples:
//                  For m simultaneous tests at level α:
//                  Step 1: Order p-values smallest to largest
//
// Rules:
//   • NEVER rely on Unicode math auto-detection. Always wrap
//     mathematical expressions in explicit $...$ delimiters.
//   • Each $...$ renders as a separate image line; put each formula
//     on its own line.
//   • Use standard LaTeX: \frac{}{}, \bar{}, \hat{}, \sqrt{},
//     \sum, \prod, \mu, \sigma, \alpha, \chi^2, \neq, \leq, \geq,
//     \text{} (for text within math mode).
//   • For subscripts: x_1, \bar{x}_i, n_{\text{total}}
//   • For hypothesis statements: $H_0: \mu_1 = \mu_2$
//
// ──────────────────────────────────────────────────────────────────

import Foundation

// MARK: - Model

struct StatsTestDetail: Identifiable {
    let id: String
    let name: String
    let aliases: [String]
    let hypotheses: String
    let testStatistic: String
    let distribution: String
    let assumptions: [String]
    let whenToUse: String
    let whenNotToUse: String
    let notes: String
    let references: [String]
}

// MARK: - Catalog

enum StatsTestCatalog {

    /// Look up the full mathematical detail for a test by its id.
    static func detail(for id: String) -> StatsTestDetail? {
        all.first { $0.id == id }
    }

    // MARK: Complete catalog

    static let all: [StatsTestDetail] = [

        // ───────────────────────────────────────────────
        // 1. Unpaired t-test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "unpaired_t",
            name: "Unpaired (Independent) t-test",
            aliases: ["Student's t-test", "Two-sample t-test"],
            hypotheses: """
                $H_0: \\mu_1 = \\mu_2$
                $H_1: \\mu_1 \\neq \\mu_2$
                """,
            testStatistic: """
                $t = \\frac{\\bar{x}_1 - \\bar{x}_2}{\\sqrt{s_p^2 \\left(\\frac{1}{n_1} + \\frac{1}{n_2}\\right)}}$
                # where the pooled variance is:
                $s_p^2 = \\frac{(n_1 - 1)s_1^2 + (n_2 - 1)s_2^2}{n_1 + n_2 - 2}$
                """,
            distribution: "t-distribution with df = n\u{2081} + n\u{2082} \u{2212} 2",
            assumptions: [
                "Observations are independent",
                "Both populations are normally distributed",
                "Equal variances in both groups (homoscedasticity)"
            ],
            whenToUse: "Comparing means of two independent groups with a continuous outcome when normality and equal variance hold.",
            whenNotToUse: "When variances are unequal (use Welch's t-test), data are non-normal (use Mann-Whitney U), or you have paired/matched data (use paired t-test).",
            notes: "The pooled variance estimate gives more power than Welch's when the equal-variance assumption is met. Refraction automatically uses Welch's when Levene's test rejects equal variance.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.3.2 (Two-sample t-test).",
                "Lehmann, E.L. & Romano, J.P. (2005). Testing Statistical Hypotheses, 3rd ed. Springer. Ch. 5."
            ]
        ),

        // ───────────────────────────────────────────────
        // 2. Welch's t-test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "welch_t",
            name: "Welch's t-test",
            aliases: ["Unequal variance t-test"],
            hypotheses: """
                $H_0: \\mu_1 = \\mu_2$
                $H_1: \\mu_1 \\neq \\mu_2$
                """,
            testStatistic: """
                $t = \\frac{\\bar{x}_1 - \\bar{x}_2}{\\sqrt{\\frac{s_1^2}{n_1} + \\frac{s_2^2}{n_2}}}$
                # Welch-Satterthwaite degrees of freedom:
                $df = \\frac{\\left(\\frac{s_1^2}{n_1} + \\frac{s_2^2}{n_2}\\right)^2}{\\frac{(s_1^2/n_1)^2}{n_1 - 1} + \\frac{(s_2^2/n_2)^2}{n_2 - 1}}$
                """,
            distribution: "t-distribution with Welch-Satterthwaite adjusted df (not necessarily integer)",
            assumptions: [
                "Observations are independent",
                "Both populations are normally distributed"
            ],
            whenToUse: "Comparing means of two independent groups when variances may differ. This is the default two-sample test in many modern packages.",
            whenNotToUse: "When data are non-normal (use Mann-Whitney U) or paired (use paired t-test). When variances are known to be equal, the pooled t-test has slightly more power.",
            notes: "Welch's t-test does NOT assume equal variances. The degrees of freedom are typically non-integer and are rounded down for table look-up. Many statisticians recommend always using Welch's t-test instead of Student's.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.3.2 (Two-sample t-test).",
                "Lehmann, E.L. & Romano, J.P. (2005). Testing Statistical Hypotheses, 3rd ed. Springer. Ch. 5."
            ]
        ),

        // ───────────────────────────────────────────────
        // 3. Paired t-test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "paired_t",
            name: "Paired t-test",
            aliases: ["Dependent t-test", "Matched-pairs t-test"],
            hypotheses: """
                $H_0: \\mu_d = 0$
                # where d = paired differences.
                $H_1: \\mu_d \\neq 0$
                """,
            testStatistic: """
                $t = \\frac{\\bar{d}}{s_d / \\sqrt{n}}$
                # where d-bar = mean of differences,
                # s_d = standard deviation of differences,
                # n = number of pairs.
                """,
            distribution: "t-distribution with df = n \u{2212} 1",
            assumptions: [
                "Observations are paired (matched)",
                "Differences are normally distributed",
                "Differences are independent of each other"
            ],
            whenToUse: "Comparing two measurements on the same subjects (before/after, left/right) or on matched pairs.",
            whenNotToUse: "When groups are independent (use unpaired t-test) or differences are non-normal (use Wilcoxon signed-rank test).",
            notes: "The paired t-test works on the differences, not the raw values. It is more powerful than the unpaired test when pairing is effective because it controls for between-subject variability.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.3.2 (Two-sample t-test).",
                "Lehmann, E.L. & Romano, J.P. (2005). Testing Statistical Hypotheses, 3rd ed. Springer. Ch. 5."
            ]
        ),

        // ───────────────────────────────────────────────
        // 4. One-way ANOVA
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "anova",
            name: "One-way ANOVA",
            aliases: ["Analysis of variance", "F-test for k groups"],
            hypotheses: """
                $H_0: \\mu_1 = \\mu_2 = \\cdots = \\mu_k$
                $H_1: \\text{At least one } \\mu_i \\text{ differs}$
                """,
            testStatistic: """
                $F = \\frac{MS_{\\text{between}}}{MS_{\\text{within}}}$
                $SS_{\\text{between}} = \\sum n_i (\\bar{x}_i - \\bar{x})^2$
                $SS_{\\text{within}} = \\sum \\sum (x_{ij} - \\bar{x}_i)^2$
                $MS_{\\text{between}} = \\frac{SS_{\\text{between}}}{k - 1}$
                $MS_{\\text{within}} = \\frac{SS_{\\text{within}}}{N - k}$
                """,
            distribution: "F-distribution with df\u{2081} = k \u{2212} 1, df\u{2082} = N \u{2212} k",
            assumptions: [
                "Observations are independent",
                "Each group is normally distributed",
                "Equal variances across groups (homoscedasticity)"
            ],
            whenToUse: "Comparing means of three or more independent groups. Follow up with a posthoc test (e.g. Tukey HSD) to identify which pairs differ.",
            whenNotToUse: "When variances are unequal (use Welch's ANOVA), data are non-normal (use Kruskal-Wallis), or observations are paired (use repeated measures ANOVA).",
            notes: "ANOVA only tells you that at least one group differs; it does not tell you which ones. Always follow a significant ANOVA with a posthoc test. Refraction uses Tukey HSD by default.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.4 (Likelihood ratio tests).",
                "Scheffé, H. (1959). The Analysis of Variance. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 5. Welch's ANOVA
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "welch_anova",
            name: "Welch's ANOVA",
            aliases: ["Welch's F-test"],
            hypotheses: """
                $H_0: \\mu_1 = \\mu_2 = \\cdots = \\mu_k$
                $H_1: \\text{At least one } \\mu_i \\text{ differs}$
                """,
            testStatistic: """
                Uses weighted group means and a modified F-statistic
                that does not pool variances.
                $w_i = \\frac{n_i}{s_i^2}$
                # The test statistic follows an approximate F-distribution
                # with adjusted degrees of freedom.
                """,
            distribution: "Approximate F-distribution with adjusted degrees of freedom",
            assumptions: [
                "Observations are independent",
                "Each group is normally distributed"
            ],
            whenToUse: "Comparing means of three or more independent groups when Levene's test indicates unequal variances. Follow up with Games-Howell for posthoc comparisons.",
            whenNotToUse: "When data are non-normal (use Kruskal-Wallis) or when observations are paired/repeated (use repeated measures ANOVA).",
            notes: "Welch's ANOVA does NOT assume equal variances. It reduces to Welch's t-test for k = 2. Games-Howell is the recommended posthoc test because it also does not assume equal variances.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.4 (Likelihood ratio tests).",
                "Scheffé, H. (1959). The Analysis of Variance. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 6. Repeated measures ANOVA
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "repeated_measures_anova",
            name: "Repeated Measures ANOVA",
            aliases: ["Within-subjects ANOVA"],
            hypotheses: """
                $H_0: \\mu_1 = \\mu_2 = \\cdots = \\mu_k$
                # across conditions.
                $H_1: \\text{At least one condition mean differs}$
                """,
            testStatistic: """
                $F = \\frac{MS_{\\text{conditions}}}{MS_{\\text{error}}}$
                Total variance is partitioned into:
                $SS_{\\text{total}} = SS_{\\text{between subjects}} + SS_{\\text{conditions}} + SS_{\\text{error}}$
                $df_{\\text{conditions}} = k - 1$
                $df_{\\text{error}} = (n - 1)(k - 1)$
                """,
            distribution: "F-distribution with df\u{2081} = k \u{2212} 1, df\u{2082} = (n \u{2212} 1)(k \u{2212} 1)",
            assumptions: [
                "Normally distributed data in each condition",
                "Sphericity: equal variances of differences between all pairs of conditions (Mauchly's test)",
                "Observations within subjects are related"
            ],
            whenToUse: "Comparing three or more measurements on the same subjects across time or conditions (e.g. pre, during, post treatment).",
            whenNotToUse: "When observations are independent (use one-way ANOVA) or data are non-normal (use Friedman test).",
            notes: "When sphericity is violated (Mauchly's test significant), apply Greenhouse-Geisser or Huynh-Feldt correction to the degrees of freedom. Refraction applies Greenhouse-Geisser automatically when needed.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.4 (Likelihood ratio tests).",
                "Scheffé, H. (1959). The Analysis of Variance. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 7. Two-way ANOVA
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "two_way_anova",
            name: "Two-way ANOVA",
            aliases: ["Factorial ANOVA", "Two-factor ANOVA"],
            hypotheses: """
                $H_{0A}: \\text{No main effect of Factor A}$
                $H_{0B}: \\text{No main effect of Factor B}$
                $H_{0AB}: \\text{No interaction between A and B}$
                """,
            testStatistic: """
                Three separate F-tests (Type III SS):
                $F_A = \\frac{MS_A}{MS_{\\text{error}}}$
                # main effect of A.
                $F_B = \\frac{MS_B}{MS_{\\text{error}}}$
                # main effect of B.
                $F_{AB} = \\frac{MS_{AB}}{MS_{\\text{error}}}$
                # interaction.
                Each SS is computed after removing all other effects
                (Type III sum of squares).
                """,
            distribution: """
                F_A:  F with df\u{2081} = a \u{2212} 1, df\u{2082} = N \u{2212} ab
                F_B:  F with df\u{2081} = b \u{2212} 1, df\u{2082} = N \u{2212} ab
                F_AB: F with df\u{2081} = (a\u{2212}1)(b\u{2212}1), df\u{2082} = N \u{2212} ab
                """,
            assumptions: [
                "Observations are independent",
                "Normality within each cell",
                "Equal variances across cells (homoscedasticity)"
            ],
            whenToUse: "When data are classified by two categorical factors and you want to test main effects and their interaction (e.g. drug \u{00D7} dose).",
            whenNotToUse: "When there is only one factor (use one-way ANOVA) or when cell sizes are very unbalanced with non-normal data.",
            notes: "Refraction uses Type III sum of squares so each effect is tested after removing all other effects. Always examine the interaction first: if significant, main effects must be interpreted cautiously.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.4 (Likelihood ratio tests).",
                "Scheffé, H. (1959). The Analysis of Variance. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 8. One-sample t-test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "one_sample_t",
            name: "One-sample t-test",
            aliases: ["Single-sample t-test"],
            hypotheses: """
                $H_0: \\mu = \\mu_0$
                # population mean equals a hypothesized value.
                $H_1: \\mu \\neq \\mu_0$
                """,
            testStatistic: """
                $t = \\frac{\\bar{x} - \\mu_0}{s / \\sqrt{n}}$
                # where x-bar = sample mean,
                # mu_0 = hypothesized value,
                # s = sample standard deviation.
                """,
            distribution: "t-distribution with df = n \u{2212} 1",
            assumptions: [
                "Observations are independent",
                "Data are normally distributed (or n is large enough for CLT)"
            ],
            whenToUse: "Testing whether a sample mean differs from a known or hypothesized value (e.g. testing if mean = 0, mean = 100).",
            whenNotToUse: "When data are severely non-normal with small n (use Wilcoxon signed-rank against the hypothesized median) or when comparing two groups (use two-sample tests).",
            notes: "The default hypothesized value in Refraction is 0. You can change it in the analysis configuration. For large n (\u{2265} 30), the test is robust to moderate non-normality.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.3.2 (Two-sample t-test).",
                "Lehmann, E.L. & Romano, J.P. (2005). Testing Statistical Hypotheses, 3rd ed. Springer. Ch. 5."
            ]
        ),

        // ───────────────────────────────────────────────
        // 9. Mann-Whitney U test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "mann_whitney",
            name: "Mann-Whitney U test",
            aliases: ["Wilcoxon rank-sum test", "Mann-Whitney-Wilcoxon"],
            hypotheses: """
                $H_0: \\text{The two groups have the same distribution}$
                $H_1: \\text{The distributions differ}$
                """,
            testStatistic: """
                $U = n_1 n_2 + \\frac{n_1(n_1 + 1)}{2} - R_1$
                # where R_1 = sum of ranks in group 1
                # (after ranking all observations together).
                For large samples, use normal approximation:
                $z = \\frac{U - \\frac{n_1 n_2}{2}}{\\sqrt{\\frac{n_1 n_2 (n_1 + n_2 + 1)}{12}}}$
                """,
            distribution: "Exact tables for small n; normal approximation for large n",
            assumptions: [
                "Observations are independent",
                "Ordinal or continuous data",
                "Similar distribution shapes (for interpreting as a location shift)"
            ],
            whenToUse: "Comparing two independent groups when data are not normally distributed, are ordinal, or have outliers that would distort a t-test.",
            whenNotToUse: "When data are paired (use Wilcoxon signed-rank) or when there are 3+ groups (use Kruskal-Wallis).",
            notes: "Ties are handled by assigning the average rank to tied observations. The tie correction adjusts the variance in the z-approximation. This test is often called the Wilcoxon rank-sum test, which is mathematically equivalent.",
            references: [
                "Hollander, M., Wolfe, D.A. & Chicken, E. (2014). Nonparametric Statistical Methods, 3rd ed. Wiley.",
                "Lehmann, E.L. (2006). Nonparametrics: Statistical Methods Based on Ranks. Springer."
            ]
        ),

        // ───────────────────────────────────────────────
        // 10. Wilcoxon signed-rank test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "wilcoxon",
            name: "Wilcoxon Signed-Rank test",
            aliases: ["Wilcoxon matched-pairs signed-rank test"],
            hypotheses: """
                $H_0: \\text{Median of differences} = 0$
                $H_1: \\text{Median of differences} \\neq 0$
                """,
            testStatistic: """
                $1.\\; \\text{Compute differences } d_i = x_i - y_i$
                $2.\\; \\text{Discard zeros, rank } |d_i|$
                $3.\\; T^+ = \\text{sum of ranks of positive differences}$
                $4.\\; T^- = \\text{sum of ranks of negative differences}$
                $5.\\; T = \\min(T^+, T^-)$
                """,
            distribution: "Exact tables for small n; normal approximation for n > 25",
            assumptions: [
                "Paired observations",
                "Differences are symmetric around the median",
                "Continuous or ordinal data"
            ],
            whenToUse: "Comparing two related measurements when the paired differences are not normally distributed.",
            whenNotToUse: "When groups are independent (use Mann-Whitney U) or when differences are normal (paired t-test is more powerful).",
            notes: "Pairs with zero difference are discarded, which reduces the effective sample size. For very small n (< 6), the test has limited power.",
            references: [
                "Hollander, M., Wolfe, D.A. & Chicken, E. (2014). Nonparametric Statistical Methods, 3rd ed. Wiley.",
                "Lehmann, E.L. (2006). Nonparametrics: Statistical Methods Based on Ranks. Springer."
            ]
        ),

        // ───────────────────────────────────────────────
        // 11. Kruskal-Wallis test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "kruskal_wallis",
            name: "Kruskal-Wallis test",
            aliases: ["Kruskal-Wallis H test", "Kruskal-Wallis one-way ANOVA by ranks"],
            hypotheses: """
                $H_0: \\text{All } k \\text{ populations have the same distribution}$
                $H_1: \\text{At least one population differs}$
                """,
            testStatistic: """
                $H = \\frac{12}{N(N+1)} \\sum \\frac{R_i^2}{n_i} - 3(N+1)$
                # where R_i = sum of ranks in group i,
                # N = total number of observations,
                # n_i = number in group i.
                """,
            distribution: "\u{03C7}\u{00B2} distribution with df = k \u{2212} 1 (for large samples)",
            assumptions: [
                "Observations are independent",
                "Ordinal or continuous data",
                "Similar distribution shapes across groups"
            ],
            whenToUse: "Comparing three or more independent groups when data are not normally distributed. Follow up with Dunn's test for pairwise comparisons.",
            whenNotToUse: "When data are paired/repeated (use Friedman test) or when data are normal with equal variances (one-way ANOVA is more powerful).",
            notes: "This is the nonparametric analogue of one-way ANOVA. A tie correction factor is applied when there are tied ranks. Refraction uses Dunn's test with Bonferroni or Holm correction for posthoc comparisons.",
            references: [
                "Hollander, M., Wolfe, D.A. & Chicken, E. (2014). Nonparametric Statistical Methods, 3rd ed. Wiley.",
                "Lehmann, E.L. (2006). Nonparametrics: Statistical Methods Based on Ranks. Springer."
            ]
        ),

        // ───────────────────────────────────────────────
        // 12. Friedman test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "friedman",
            name: "Friedman test",
            aliases: ["Friedman two-way ANOVA by ranks"],
            hypotheses: """
                $H_0: \\text{All } k \\text{ treatments have the same effect}$
                $H_1: \\text{At least one treatment differs}$
                """,
            testStatistic: """
                $\\chi^2_F = \\frac{12}{bk(k+1)} \\sum R_j^2 - 3b(k+1)$
                # where b = number of blocks (subjects),
                # k = number of treatments (conditions),
                # R_j = sum of ranks for treatment j.
                """,
            distribution: "\u{03C7}\u{00B2} distribution with df = k \u{2212} 1 (for large b or k)",
            assumptions: [
                "Data are paired/repeated (blocked by subject)",
                "Ordinal or continuous data",
                "Rankings within each block are independent"
            ],
            whenToUse: "Comparing three or more related groups (same subjects across conditions) when data are not normally distributed.",
            whenNotToUse: "When groups are independent (use Kruskal-Wallis) or when data meet normality and sphericity (repeated measures ANOVA is more powerful).",
            notes: "This is the nonparametric analogue of repeated measures ANOVA. Data are ranked within each subject (block) independently.",
            references: [
                "Hollander, M., Wolfe, D.A. & Chicken, E. (2014). Nonparametric Statistical Methods, 3rd ed. Wiley.",
                "Lehmann, E.L. (2006). Nonparametrics: Statistical Methods Based on Ranks. Springer."
            ]
        ),

        // ───────────────────────────────────────────────
        // 13. Chi-square test of independence
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "chi_square",
            name: "Chi-square test of independence",
            aliases: ["Pearson's chi-square test", "\u{03C7}\u{00B2} test"],
            hypotheses: """
                $H_0: \\text{The two categorical variables are independent}$
                $H_1: \\text{The two variables are associated}$
                """,
            testStatistic: """
                $\\chi^2 = \\sum \\sum \\frac{(O_{ij} - E_{ij})^2}{E_{ij}}$
                # where E_ij = (row total x column total) / N,
                # O_ij = observed count in cell (i, j).
                """,
            distribution: "\u{03C7}\u{00B2} distribution with df = (r \u{2212} 1)(c \u{2212} 1)",
            assumptions: [
                "Observations are independent",
                "Expected count \u{2265} 5 in each cell (rule of thumb)",
                "Data are counts (not percentages or rates)"
            ],
            whenToUse: "Testing whether two categorical variables are associated in a contingency table, when all expected counts are at least 5.",
            whenNotToUse: "When expected counts are small (use Fisher's exact test for 2\u{00D7}2 tables) or when data are paired (use McNemar's test).",
            notes: "Yates' continuity correction is sometimes applied for 2\u{00D7}2 tables but is conservative. Refraction reports the uncorrected \u{03C7}\u{00B2} by default and falls back to Fisher's exact test when expected counts are too small.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.4.3 (Chi-square tests).",
                "Agresti, A. (2013). Categorical Data Analysis, 3rd ed. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 14. Fisher's exact test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "fisher_exact",
            name: "Fisher's exact test",
            aliases: ["Fisher-Irwin test"],
            hypotheses: """
                $H_0: \\text{The two variables are independent (odds ratio} = 1\\text{)}$
                $H_1: \\text{The two variables are associated (odds ratio} \\neq 1\\text{)}$
                """,
            testStatistic: """
                For a 2x2 table with cells a, b, c, d:
                $p = \\frac{(a+b)!\\,(c+d)!\\,(a+c)!\\,(b+d)!}{N!\\, a!\\, b!\\, c!\\, d!}$
                Sum probabilities for all tables as extreme or more
                extreme than the observed, given fixed marginals.
                """,
            distribution: "Hypergeometric distribution (exact, not asymptotic)",
            assumptions: [
                "Observations are independent",
                "Fixed marginal totals (or conditioned on them)"
            ],
            whenToUse: "Testing association in a 2\u{00D7}2 contingency table, especially when sample sizes are small or expected counts fall below 5.",
            whenNotToUse: "For larger tables (r\u{00D7}c with r > 2 or c > 2) where computation may be expensive, or when the chi-square approximation is adequate.",
            notes: "Fisher's exact test computes exact probabilities rather than relying on the chi-square approximation. It is always valid but is most useful when the sample is small. For large samples, it gives results very close to the chi-square test.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.4.3 (Chi-square tests).",
                "Agresti, A. (2013). Categorical Data Analysis, 3rd ed. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 15. Chi-square goodness of fit
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "chi_square_gof",
            name: "Chi-square goodness of fit",
            aliases: ["One-sample chi-square test"],
            hypotheses: """
                $H_0: \\text{Observed frequencies match the expected distribution}$
                $H_1: \\text{Observed frequencies differ from expected}$
                """,
            testStatistic: """
                $\\chi^2 = \\sum \\frac{(O_i - E_i)^2}{E_i}$
                # where O_i = observed count in category i,
                # E_i = expected count in category i.
                """,
            distribution: "\u{03C7}\u{00B2} distribution with df = k \u{2212} 1 (or k \u{2212} 1 \u{2212} p if p parameters were estimated from the data)",
            assumptions: [
                "Observations are independent",
                "Expected count \u{2265} 5 in each category",
                "Data are counts"
            ],
            whenToUse: "Testing whether observed frequencies match a hypothesized distribution (e.g. equal frequencies, Mendelian ratios).",
            whenNotToUse: "When expected counts are very small (combine categories first) or when testing association between two variables (use chi-square test of independence).",
            notes: "If you estimated parameters from the data to calculate expected values, subtract those from the degrees of freedom. For example, testing normality with estimated mean and SD uses df = k \u{2212} 3.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.4.3 (Chi-square tests).",
                "Agresti, A. (2013). Categorical Data Analysis, 3rd ed. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 16. McNemar's test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "mcnemar",
            name: "McNemar's test",
            aliases: ["McNemar's chi-square test"],
            hypotheses: """
                $H_0: \\text{The marginal proportions are equal}$
                $H_1: \\text{The marginal proportions differ}$
                """,
            testStatistic: """
                For a paired 2x2 table with concordant (a, d) and
                discordant (b, c) pairs:
                $\\chi^2 = \\frac{(b - c)^2}{b + c}$
                # Only discordant pairs (b and c) contribute.
                """,
            distribution: "\u{03C7}\u{00B2} distribution with df = 1",
            assumptions: [
                "Paired observations (before/after on same subjects)",
                "Binary (dichotomous) outcome",
                "b + c (discordant pairs) is sufficiently large (\u{2265} 10)"
            ],
            whenToUse: "Testing whether the proportion of successes changes from before to after an intervention, using matched binary data.",
            whenNotToUse: "When data are not paired (use chi-square test of independence) or when the outcome has more than two levels.",
            notes: "With continuity correction: \u{03C7}\u{00B2} = (|b \u{2212} c| \u{2212} 1)\u{00B2} / (b + c). An exact binomial test on the discordant pairs can be used when b + c is small.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.4.3 (Chi-square tests).",
                "Agresti, A. (2013). Categorical Data Analysis, 3rd ed. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 17. Pearson correlation
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "pearson",
            name: "Pearson correlation coefficient",
            aliases: ["Pearson's r", "Product-moment correlation"],
            hypotheses: """
                $H_0: \\rho = 0$
                # no linear association.
                $H_1: \\rho \\neq 0$
                """,
            testStatistic: """
                $r = \\frac{\\sum (x_i - \\bar{x})(y_i - \\bar{y})}{\\sqrt{\\sum (x_i - \\bar{x})^2 \\sum (y_i - \\bar{y})^2}}$
                Test statistic:
                $t = \\frac{r \\sqrt{n - 2}}{\\sqrt{1 - r^2}}$
                """,
            distribution: "t-distribution with df = n \u{2212} 2 (for the significance test)",
            assumptions: [
                "Bivariate normality",
                "Linear relationship between variables",
                "Both variables are continuous",
                "No significant outliers"
            ],
            whenToUse: "Measuring the strength and direction of a linear relationship between two continuous, normally distributed variables.",
            whenNotToUse: "When the relationship is non-linear (consider transformation or Spearman), data have outliers (use Spearman), or variables are ordinal (use Spearman).",
            notes: "r ranges from \u{2212}1 (perfect negative) to +1 (perfect positive). r\u{00B2} gives the proportion of variance explained. Pearson's r only captures linear relationships; a non-significant r does not mean no association.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §11.3 (Regression).",
                "Draper, N.R. & Smith, H. (1998). Applied Regression Analysis, 3rd ed. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 18. Spearman correlation
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "spearman",
            name: "Spearman rank correlation",
            aliases: ["Spearman's rho", "Spearman's r\u{209B}"],
            hypotheses: """
                $H_0: \\rho_s = 0$
                # no monotonic association.
                $H_1: \\rho_s \\neq 0$
                """,
            testStatistic: """
                $r_s = \\text{Pearson } r \\text{ computed on the ranks}$
                When there are no ties:
                $r_s = 1 - \\frac{6 \\sum d_i^2}{n(n^2 - 1)}$
                # where d_i = rank(x_i) - rank(y_i).
                """,
            distribution: "Exact tables for small n; t-approximation with df = n \u{2212} 2 for large n",
            assumptions: [
                "Paired observations",
                "Ordinal or continuous data",
                "Monotonic (not necessarily linear) relationship"
            ],
            whenToUse: "Measuring the strength and direction of a monotonic relationship, especially when data are ordinal, non-normal, or have outliers.",
            whenNotToUse: "When you specifically need to detect only linear relationships and data are bivariate normal (Pearson is more powerful in that case).",
            notes: "Spearman's r\u{209B} is robust to outliers because it operates on ranks. It captures any monotonic relationship, not just linear ones. The shortcut formula (with d\u{1D62}\u{00B2}) only works when there are no tied ranks.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §11.3 (Regression).",
                "Draper, N.R. & Smith, H. (1998). Applied Regression Analysis, 3rd ed. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 19. Simple linear regression
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "linear_regression",
            name: "Simple linear regression",
            aliases: ["Ordinary least squares (OLS)", "Linear model"],
            hypotheses: """
                $H_0: \\beta_1 = 0$
                # slope is zero; X does not predict Y.
                $H_1: \\beta_1 \\neq 0$
                """,
            testStatistic: """
                $\\hat{y} = a + bx$
                $b = \\frac{\\sum (x_i - \\bar{x})(y_i - \\bar{y})}{\\sum (x_i - \\bar{x})^2}$
                $a = \\bar{y} - b\\bar{x}$
                $R^2 = \\frac{SS_{\\text{regression}}}{SS_{\\text{total}}}$
                $F = \\frac{MS_{\\text{regression}}}{MS_{\\text{residual}}}$
                # with df_1 = 1, df_2 = n - 2.
                """,
            distribution: "F-distribution with df\u{2081} = 1, df\u{2082} = n \u{2212} 2 for the overall model; t with df = n \u{2212} 2 for the slope",
            assumptions: [
                "Linear relationship between X and Y",
                "Residuals are normally distributed",
                "Homoscedasticity (constant variance of residuals)",
                "Independence of observations"
            ],
            whenToUse: "Modeling a linear relationship between a single predictor and a continuous outcome. Provides slope, intercept, R\u{00B2}, and prediction intervals.",
            whenNotToUse: "When the relationship is non-linear (consider polynomial or nonlinear regression), when there are multiple predictors (use multiple regression), or when residuals are severely non-normal.",
            notes: "R\u{00B2} measures the fraction of variance in Y explained by X. A high R\u{00B2} does not imply causation. Always inspect a residual plot to verify assumptions.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §11.3 (Regression).",
                "Draper, N.R. & Smith, H. (1998). Applied Regression Analysis, 3rd ed. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 20. Log-rank test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "log_rank",
            name: "Log-rank test",
            aliases: ["Mantel-Cox test"],
            hypotheses: """
                $H_0: \\text{Survival functions are equal across groups}$
                $H_1: \\text{At least one group's survival function differs}$
                """,
            testStatistic: """
                $\\chi^2 = \\frac{\\left(\\sum (O_{1j} - E_{1j})\\right)^2}{\\sum \\text{Var}_{1j}}$
                At each event time j:
                $E_{1j} = \\frac{d_j \\times n_{1j}}{n_j}$
                # where d_j = total events at time j,
                # n_{1j} = at-risk in group 1,
                # n_j = total at-risk.
                """,
            distribution: "\u{03C7}\u{00B2} distribution with df = k \u{2212} 1 (k = number of groups)",
            assumptions: [
                "Non-informative censoring (censoring is independent of prognosis)",
                "Proportional hazards (hazard ratio is constant over time)"
            ],
            whenToUse: "Comparing survival curves between two or more groups with possibly censored time-to-event data.",
            whenNotToUse: "When hazards are clearly non-proportional (crossing survival curves) \u{2014} consider Gehan-Wilcoxon or stratified analysis. When you need to adjust for covariates, use Cox regression.",
            notes: "The log-rank test gives equal weight to all time points. If early events are more important, the Gehan-Wilcoxon test (which weights earlier events more) may be more appropriate.",
            references: [
                "Collett, D. (2015). Modelling Survival Data in Medical Research, 3rd ed. CRC Press.",
                "Klein, J.P. & Moeschberger, M.L. (2003). Survival Analysis, 2nd ed. Springer."
            ]
        ),

        // ───────────────────────────────────────────────
        // 21. Kaplan-Meier estimator
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "kaplan_meier",
            name: "Kaplan-Meier estimator",
            aliases: ["Product-limit estimator", "KM curve"],
            hypotheses: """
                Descriptive method -- no hypothesis test per se.
                Use the log-rank test to compare KM curves between groups.
                """,
            testStatistic: """
                $\\hat{S}(t) = \\prod_{t_i \\leq t} \\left(1 - \\frac{d_i}{n_i}\\right)$
                # where d_i = events at time t_i,
                # n_i = number at risk just before t_i.
                Greenwood variance:
                $\\text{Var}(\\hat{S}(t)) = \\hat{S}(t)^2 \\sum \\frac{d_i}{n_i(n_i - d_i)}$
                """,
            distribution: "Pointwise confidence intervals use log or log-log transformation",
            assumptions: [
                "Non-informative censoring",
                "Event times are independent",
                "Survival probability depends only on time since origin"
            ],
            whenToUse: "Estimating the survival function from censored time-to-event data. Produces the classic step-function survival curve.",
            whenNotToUse: "When you need to adjust for covariates (use Cox regression) or when there is no censoring (simpler methods suffice).",
            notes: "Censored observations are indicated by a + or tick on the curve. The KM estimator handles right-censoring naturally. Median survival is the time at which S-hat(t) = 0.5.",
            references: [
                "Collett, D. (2015). Modelling Survival Data in Medical Research, 3rd ed. CRC Press.",
                "Klein, J.P. & Moeschberger, M.L. (2003). Survival Analysis, 2nd ed. Springer."
            ]
        ),

        // ───────────────────────────────────────────────
        // 22. Tukey HSD
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "tukey_hsd",
            name: "Tukey's Honest Significant Difference (HSD)",
            aliases: ["Tukey-Kramer test", "Tukey's range test"],
            hypotheses: """
                For each pair (i, j):
                $H_0: \\mu_i = \\mu_j$
                $H_1: \\mu_i \\neq \\mu_j$
                """,
            testStatistic: """
                $q = \\frac{\\bar{x}_i - \\bar{x}_j}{\\sqrt{MS_{\\text{within}} / n}}$
                For unequal group sizes (Tukey-Kramer):
                $q = \\frac{\\bar{x}_i - \\bar{x}_j}{\\sqrt{\\frac{MS_{\\text{within}}}{2} \\left(\\frac{1}{n_i} + \\frac{1}{n_j}\\right)}}$
                """,
            distribution: "Studentized range distribution with k groups and df = N \u{2212} k",
            assumptions: [
                "One-way ANOVA assumptions (normality, equal variance, independence)",
                "All pairwise comparisons are of interest"
            ],
            whenToUse: "Following a significant one-way ANOVA to identify which specific pairs of group means differ, while controlling the family-wise error rate.",
            whenNotToUse: "When variances are unequal (use Games-Howell), when only comparisons to a control are needed (use Dunnett's), or after Kruskal-Wallis (use Dunn's test).",
            notes: "Tukey HSD controls the family-wise Type I error rate at \u{03B1} simultaneously for all pairwise comparisons. It is the most common posthoc test in biology and is the default in Refraction.",
            references: [
                "Hochberg, Y. & Tamhane, A.C. (1987). Multiple Comparison Procedures. Wiley.",
                "Hollander, M., Wolfe, D.A. & Chicken, E. (2014). Nonparametric Statistical Methods, 3rd ed. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 23. Dunn's test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "dunns_test",
            name: "Dunn's test",
            aliases: ["Dunn's multiple comparison test"],
            hypotheses: """
                For each pair (i, j):
                $H_0: \\text{Group } i \\text{ and group } j \\text{ have the same distribution}$
                $H_1: \\text{The distributions differ}$
                """,
            testStatistic: """
                $z = \\frac{\\bar{R}_i - \\bar{R}_j}{\\sqrt{\\frac{N(N+1)}{12} \\left(\\frac{1}{n_i} + \\frac{1}{n_j}\\right)}}$
                # where R-bar_i = mean rank for group i,
                # N = total sample size.
                Apply Bonferroni or Holm correction to the p-values.
                """,
            distribution: "Standard normal (z) for each pairwise comparison",
            assumptions: [
                "Data are ranked (follows Kruskal-Wallis)",
                "Groups are independent"
            ],
            whenToUse: "Following a significant Kruskal-Wallis test to identify which pairs of groups differ.",
            whenNotToUse: "After a parametric ANOVA (use Tukey HSD instead) or when data are paired.",
            notes: "Dunn's test uses the same ranking from the Kruskal-Wallis test. Refraction applies either Bonferroni or Holm-Bonferroni correction to control the family-wise error rate.",
            references: [
                "Hochberg, Y. & Tamhane, A.C. (1987). Multiple Comparison Procedures. Wiley.",
                "Hollander, M., Wolfe, D.A. & Chicken, E. (2014). Nonparametric Statistical Methods, 3rd ed. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 24. Dunnett's test
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "dunnetts_test",
            name: "Dunnett's test",
            aliases: ["Dunnett's many-to-one comparisons"],
            hypotheses: """
                For each treatment i vs control:
                $H_0: \\mu_i = \\mu_{\\text{control}}$
                $H_1: \\mu_i \\neq \\mu_{\\text{control}}$
                """,
            testStatistic: """
                $t = \\frac{\\bar{x}_i - \\bar{x}_{\\text{control}}}{\\sqrt{MS_{\\text{within}} \\left(\\frac{1}{n_i} + \\frac{1}{n_{\\text{control}}}\\right)}}$
                # Critical values come from the multivariate t-distribution
                # accounting for the correlation structure between comparisons.
                """,
            distribution: "Multivariate t-distribution with df = N \u{2212} k and k \u{2212} 1 comparisons",
            assumptions: [
                "One-way ANOVA assumptions (normality, equal variance, independence)",
                "Only comparisons to a single control group are of interest"
            ],
            whenToUse: "Comparing multiple treatment groups against a single control, while controlling the family-wise error rate for only those specific comparisons.",
            whenNotToUse: "When all pairwise comparisons are needed (use Tukey HSD) or after a nonparametric test.",
            notes: "Dunnett's test is more powerful than Tukey for control-vs-treatment comparisons because it makes fewer comparisons. In Refraction, set the control group in the analysis configuration.",
            references: [
                "Hochberg, Y. & Tamhane, A.C. (1987). Multiple Comparison Procedures. Wiley.",
                "Hollander, M., Wolfe, D.A. & Chicken, E. (2014). Nonparametric Statistical Methods, 3rd ed. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 25. Games-Howell
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "games_howell",
            name: "Games-Howell test",
            aliases: ["Games-Howell posthoc"],
            hypotheses: """
                For each pair (i, j):
                $H_0: \\mu_i = \\mu_j$
                $H_1: \\mu_i \\neq \\mu_j$
                """,
            testStatistic: """
                $q = \\frac{\\bar{x}_i - \\bar{x}_j}{\\sqrt{\\frac{s_i^2/n_i + s_j^2/n_j}{2}}}$
                # Welch-Satterthwaite df for each pair:
                $df = \\frac{\\left(\\frac{s_i^2}{n_i} + \\frac{s_j^2}{n_j}\\right)^2}{\\frac{(s_i^2/n_i)^2}{n_i - 1} + \\frac{(s_j^2/n_j)^2}{n_j - 1}}$
                """,
            distribution: "Studentized range distribution with pair-specific df",
            assumptions: [
                "Normality within each group",
                "Groups are independent"
            ],
            whenToUse: "Following Welch's ANOVA (or when variances are unequal) to identify which pairs differ. Does NOT assume equal variances.",
            whenNotToUse: "When variances are equal (Tukey HSD is more powerful) or after a nonparametric test.",
            notes: "Games-Howell is like Tukey HSD but uses separate variance estimates and Welch-Satterthwaite df for each pair. It is the recommended posthoc test when Levene's test rejects equal variances.",
            references: [
                "Hochberg, Y. & Tamhane, A.C. (1987). Multiple Comparison Procedures. Wiley.",
                "Hollander, M., Wolfe, D.A. & Chicken, E. (2014). Nonparametric Statistical Methods, 3rd ed. Wiley."
            ]
        ),

        // ───────────────────────────────────────────────
        // 26. Cohen's d
        // ───────────────────────────────────────────────
        StatsTestDetail(
            id: "cohens_d",
            name: "Cohen's d (effect size)",
            aliases: ["Standardized mean difference"],
            hypotheses: """
                Effect size measure -- no hypothesis test.
                Used to quantify the magnitude of a difference.
                """,
            testStatistic: """
                $d = \\frac{\\bar{x}_1 - \\bar{x}_2}{s_p}$
                # where s_p is the pooled standard deviation:
                $s_p = \\sqrt{\\frac{(n_1 - 1)s_1^2 + (n_2 - 1)s_2^2}{n_1 + n_2 - 2}}$
                Conventional thresholds (Cohen, 1988):
                $\\text{Small: } d = 0.2 \\quad \\text{Medium: } d = 0.5 \\quad \\text{Large: } d = 0.8$
                """,
            distribution: "Not a test statistic; no reference distribution",
            assumptions: [
                "Meaningful to compare means (continuous data)",
                "Pooled SD is an appropriate measure of spread"
            ],
            whenToUse: "Reporting the practical significance of a difference between two group means, independent of sample size.",
            whenNotToUse: "When comparing more than two groups (consider \u{03B7}\u{00B2} or partial \u{03B7}\u{00B2}), or when data are non-normal (consider rank-biserial correlation).",
            notes: "A statistically significant p-value does not imply a large effect. Always report an effect size alongside p-values. Cohen's thresholds are rough guidelines; the meaningful effect size depends on your field.",
            references: [
                "Cohen, J. (1988). Statistical Power Analysis for the Behavioral Sciences, 2nd ed. Erlbaum.",
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.3."
            ]
        ),

        // ───────────────────────────────────────────────
        // Additional tests from the wiki catalog
        // ───────────────────────────────────────────────

        StatsTestDetail(
            id: "multiple_regression",
            name: "Multiple linear regression",
            aliases: ["Multiple regression", "OLS with multiple predictors"],
            hypotheses: """
                $H_0: \\beta_1 = \\beta_2 = \\cdots = 0$
                # all slopes are zero.
                $H_1: \\text{At least one slope is non-zero}$
                """,
            testStatistic: """
                $\\hat{y} = \\beta_0 + \\beta_1 x_1 + \\beta_2 x_2 + \\cdots + \\beta_p x_p$
                $F = \\frac{R^2 / p}{(1 - R^2) / (n - p - 1)}$
                $t_i = \\frac{\\hat{\\beta}_i}{SE(\\hat{\\beta}_i)}$
                # Individual t-test for each coefficient.
                """,
            distribution: "F with df\u{2081} = p, df\u{2082} = n \u{2212} p \u{2212} 1 (overall); t with df = n \u{2212} p \u{2212} 1 (per coefficient)",
            assumptions: [
                "Linearity",
                "No multicollinearity among predictors",
                "Normally distributed residuals",
                "Homoscedasticity",
                "Independence of observations"
            ],
            whenToUse: "Predicting a continuous outcome from multiple predictors simultaneously.",
            whenNotToUse: "When predictors are highly correlated (multicollinearity) or when the outcome is binary (use logistic regression).",
            notes: "Check VIF (variance inflation factor) for multicollinearity. Adjusted R\u{00B2} accounts for the number of predictors and is preferred over R\u{00B2} for model comparison.",
            references: [
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §11.3 (Regression).",
                "Draper, N.R. & Smith, H. (1998). Applied Regression Analysis, 3rd ed. Wiley."
            ]
        ),

        StatsTestDetail(
            id: "gehan_wilcoxon",
            name: "Gehan-Wilcoxon test",
            aliases: ["Gehan-Breslow test", "Generalized Wilcoxon test"],
            hypotheses: """
                $H_0: \\text{Survival functions are equal across groups}$
                $H_1: \\text{Survival functions differ}$
                """,
            testStatistic: """
                Like the log-rank test but weights each event time
                by the number at risk n_j, giving more weight to
                early events when sample sizes are largest.
                $\\text{The test statistic follows a } \\chi^2 \\text{ distribution.}$
                """,
            distribution: "\u{03C7}\u{00B2} distribution with df = k \u{2212} 1",
            assumptions: [
                "Non-informative censoring",
                "Time-to-event data with possible censoring"
            ],
            whenToUse: "Comparing survival curves when early differences are more important than late differences, or when proportional hazards may not hold.",
            whenNotToUse: "When hazards are proportional and all time points are equally important (log-rank test is more standard and powerful).",
            notes: "The Gehan-Wilcoxon test is more sensitive to early survival differences. It is a good complement to the log-rank test. If both agree, the conclusion is robust.",
            references: [
                "Collett, D. (2015). Modelling Survival Data in Medical Research, 3rd ed. CRC Press.",
                "Klein, J.P. & Moeschberger, M.L. (2003). Survival Analysis, 2nd ed. Springer."
            ]
        ),

        StatsTestDetail(
            id: "cox_ph",
            name: "Cox proportional hazards regression",
            aliases: ["Cox regression", "Cox model"],
            hypotheses: """
                $H_0: \\beta = 0$
                # covariate has no effect on hazard.
                $H_1: \\beta \\neq 0$
                """,
            testStatistic: """
                $h(t) = h_0(t) \\times \\exp(\\beta_1 x_1 + \\beta_2 x_2 + \\cdots)$
                $HR = \\exp(\\beta)$
                # Hazard ratio. Coefficients estimated by partial likelihood.
                $\\text{Test using Wald } \\chi^2 \\text{ or likelihood ratio test.}$
                """,
            distribution: "\u{03C7}\u{00B2} (Wald or LR) with df = number of covariates",
            assumptions: [
                "Proportional hazards: HR is constant over time",
                "Non-informative censoring",
                "Log-linear relationship between hazard and covariates"
            ],
            whenToUse: "Modeling the effect of one or more covariates on survival time, while allowing for censoring.",
            whenNotToUse: "When the proportional hazards assumption is violated (consider stratified Cox or time-varying coefficients).",
            notes: "The baseline hazard h_0(t) is left unspecified (semi-parametric). Schoenfeld residuals can diagnose violations of proportional hazards. HR > 1 means increased hazard (worse survival).",
            references: [
                "Collett, D. (2015). Modelling Survival Data in Medical Research, 3rd ed. CRC Press.",
                "Klein, J.P. & Moeschberger, M.L. (2003). Survival Analysis, 2nd ed. Springer."
            ]
        ),

        StatsTestDetail(
            id: "permutation",
            name: "Permutation test",
            aliases: ["Randomization test", "Exact test"],
            hypotheses: """
                $H_0: \\text{Group labels are exchangeable (no difference)}$
                $H_1: \\text{Group assignment matters}$
                """,
            testStatistic: """
                1. Choose a test statistic (e.g. difference in means).
                $2.\\; \\text{Compute it for the observed data: } T_{\\text{obs}}$
                3. Randomly permute group labels many times.
                4. For each permutation, compute the test statistic.
                $5.\\; p = \\text{proportion of permuted statistics} \\geq |T_{\\text{obs}}|$
                """,
            distribution: "Empirical distribution from permutations (distribution-free)",
            assumptions: [
                "Exchangeability of observations under H\u{2080}",
                "Independent observations"
            ],
            whenToUse: "When parametric assumptions are questionable and you want an exact, distribution-free test. Particularly useful with small samples or unusual distributions.",
            whenNotToUse: "When computational cost is prohibitive (very large n) or when a well-established parametric test is appropriate.",
            notes: "Refraction uses 10,000 permutations by default for approximate p-values. The permutation test makes no distributional assumptions but does assume exchangeability under the null.",
            references: [
                "Lehmann, E.L. & Romano, J.P. (2005). Testing Statistical Hypotheses, 3rd ed. Springer.",
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.3.4."
            ]
        ),

        StatsTestDetail(
            id: "ks_test",
            name: "Kolmogorov-Smirnov test",
            aliases: ["KS test", "K-S test"],
            hypotheses: """
                $H_0: \\text{Data follow the specified distribution}$
                # (one-sample) or:
                $H_0: \\text{Both samples come from the same distribution}$
                # (two-sample).
                """,
            testStatistic: """
                $D = \\max |F_n(x) - F_0(x)|$
                # one-sample.
                $D = \\max |F_1(x) - F_2(x)|$
                # two-sample.
                # where F_n(x) = empirical CDF,
                # F_0(x) = theoretical CDF.
                """,
            distribution: "Kolmogorov-Smirnov distribution (exact tables or asymptotic)",
            assumptions: [
                "Continuous data",
                "The reference distribution is fully specified (parameters not estimated from the data)"
            ],
            whenToUse: "Testing whether data follow a specific distribution (e.g. normal) or whether two samples have the same distribution.",
            whenNotToUse: "For testing normality specifically, the Shapiro-Wilk test is more powerful. When parameters are estimated from the data, use the Lilliefors correction.",
            notes: "The KS test is sensitive to any difference in distribution (location, scale, shape) but has less power than specialized tests. The ECDF chart type in Refraction visualizes the empirical distribution that this test is based on.",
            references: [
                "Lehmann, E.L. & Romano, J.P. (2005). Testing Statistical Hypotheses, 3rd ed. Springer.",
                "Casella, G. & Berger, R.L. (2002). Statistical Inference, 2nd ed. Cengage. §8.3.4."
            ]
        ),

        // ───────────────────────────────────────────────
        // Multiple Testing Corrections
        // ───────────────────────────────────────────────

        StatsTestDetail(
            id: "bonferroni",
            name: "Bonferroni Correction",
            aliases: ["Bonferroni adjustment"],
            hypotheses: """
                For m simultaneous tests at level alpha:
                $\\text{Reject } H_0^{(i)} \\text{ if } p^{(i)} \\leq \\alpha / m$
                """,
            testStatistic: """
                $\\alpha_{\\text{adj}} = \\frac{\\alpha}{m}$
                # where m = number of comparisons.
                Equivalently, multiply each p-value by m:
                $p_{\\text{adj}}^{(i)} = \\min(m \\times p^{(i)},\\; 1)$
                """,
            distribution: "Uses the original test's distribution. Only adjusts the threshold.",
            assumptions: [
                "Valid for any dependency structure (conservative)",
                "Controls family-wise error rate (FWER) at level \u{03B1}"
            ],
            whenToUse: "When the number of comparisons is small and strict FWER control is essential (e.g., confirmatory clinical trials).",
            whenNotToUse: "When many tests are performed (becomes overly conservative, inflating Type II error). Use Holm-Bonferroni or BH-FDR instead.",
            notes: "The simplest correction but often too conservative. For k groups, ANOVA posthoc produces m = k(k-1)/2 pairwise comparisons. Example: 5 groups = 10 comparisons, so \u{03B1}_adj = 0.05/10 = 0.005. Prism uses this as the default for Dunnett-type comparisons.",
            references: [
                "Bonferroni, C.E. (1936). Teoria statistica delle classi e calcolo delle probabilit\u{00E0}.",
                "Motulsky, H.J. (2014). Intuitive Biostatistics, 4th ed. Oxford. Ch. 22.",
                "GraphPad Prism Guide: Multiple comparisons corrections."
            ]
        ),

        StatsTestDetail(
            id: "holm_bonferroni",
            name: "Holm-Bonferroni Method (Step-Down)",
            aliases: ["Holm's method", "Sequential Bonferroni", "Holm's step-down"],
            hypotheses: """
                $\\text{Order p-values: } p_{(1)} \\leq p_{(2)} \\leq \\cdots \\leq p_{(m)}$
                $\\text{Reject } H_{(i)} \\text{ if } p_{(i)} \\leq \\frac{\\alpha}{m - i + 1} \\text{ for all } j \\leq i$
                """,
            testStatistic: """
                Step-down procedure:
                $1.\\; \\text{Sort p-values: } p_{(1)} \\leq p_{(2)} \\leq \\cdots \\leq p_{(m)}$
                $2.\\; \\text{Compare } p_{(i)} \\text{ to } \\frac{\\alpha}{m - i + 1}$
                3. Reject all H(j) for j <= k, where k is the largest i
                such that p(i) <= alpha/(m - i + 1).
                Adjusted p-values:
                $p_{\\text{adj}(i)} = \\max_{j \\leq i} \\left\\{ (m - j + 1) \\times p_{(j)} \\right\\}$
                """,
            distribution: "Uses the original test's distribution. Only adjusts thresholds sequentially.",
            assumptions: [
                "Valid for ANY dependency structure between tests",
                "Uniformly more powerful than Bonferroni",
                "Controls FWER at level \u{03B1}"
            ],
            whenToUse: "Default recommendation for most multiple testing situations. Always at least as powerful as Bonferroni, often substantially more powerful. Refraction uses this as the default correction.",
            whenNotToUse: "When false discovery rate control is sufficient (use Benjamini-Hochberg for more power).",
            notes: "Holm's method is uniformly more powerful than Bonferroni \u{2014} it can never reject fewer hypotheses. It requires no assumptions about the dependency structure between tests, making it universally applicable. This is Refraction's default multiple comparison correction.",
            references: [
                "Holm, S. (1979). A simple sequentially rejective multiple test procedure. Scandinavian Journal of Statistics, 6(2), 65\u{2013}70.",
                "Motulsky, H.J. (2014). Intuitive Biostatistics, 4th ed. Oxford. Ch. 22.",
                "GraphPad Prism Guide: Holm-\u{0160}id\u{00E1}k and Holm-Bonferroni methods."
            ]
        ),

        StatsTestDetail(
            id: "benjamini_hochberg",
            name: "Benjamini-Hochberg (FDR)",
            aliases: ["BH procedure", "FDR correction", "False Discovery Rate"],
            hypotheses: """
                Controls the expected proportion of false discoveries:
                $FDR = E[V/R] \\leq q$
                # where V = false rejections, R = total rejections, q = target FDR level.
                """,
            testStatistic: """
                Step-up procedure:
                $1.\\; \\text{Sort p-values: } p_{(1)} \\leq p_{(2)} \\leq \\cdots \\leq p_{(m)}$
                $2.\\; \\text{Find largest } k \\text{ such that } p_{(k)} \\leq \\frac{k}{m} \\times q$
                3. Reject all H(i) for i <= k.
                Adjusted p-values:
                $p_{\\text{adj}(i)} = \\min_{j \\geq i} \\left\\{ \\frac{m}{j} \\times p_{(j)} \\right\\}$
                """,
            distribution: "Uses the original test's distribution.",
            assumptions: [
                "Independent or positively dependent tests (PRDS condition)",
                "Controls FDR, not FWER \u{2014} allows some false positives"
            ],
            whenToUse: "Exploratory analyses, genomics, proteomics, or any setting with many tests where some false positives are tolerable. Much more powerful than FWER methods when m is large.",
            whenNotToUse: "Confirmatory studies where any false positive is unacceptable. Use Bonferroni or Holm instead.",
            notes: "FDR controls the expected *proportion* of false discoveries among rejected hypotheses, rather than the *probability* of any false discovery. This is a fundamentally less strict criterion than FWER, which is why it has more power. For 100 tests at FDR=0.05, you expect at most 5% of the rejected hypotheses to be false positives \u{2014} but you don't know which ones.",
            references: [
                "Benjamini, Y. & Hochberg, Y. (1995). Controlling the false discovery rate: a practical and powerful approach to multiple testing. JRSS-B, 57(1), 289\u{2013}300.",
                "Storey, J.D. (2002). A direct approach to false discovery rates. JRSS-B, 64(3), 479\u{2013}498.",
                "Motulsky, H.J. (2014). Intuitive Biostatistics, 4th ed. Oxford. Ch. 22."
            ]
        ),

        StatsTestDetail(
            id: "tukey_hsd",
            name: "Tukey's Honestly Significant Difference",
            aliases: ["Tukey HSD", "Tukey's test", "Tukey-Kramer"],
            hypotheses: """
                For all pairs (i, j):
                $H_0: \\mu_i = \\mu_j$
                $H_1: \\mu_i \\neq \\mu_j$
                """,
            testStatistic: """
                $q = \\frac{\\bar{x}_1 - \\bar{x}_2}{\\sqrt{MSE / n}}$
                # where MSE = mean square error from ANOVA,
                # n = common sample size per group.
                For unequal n (Tukey-Kramer):
                $q = \\frac{\\bar{x}_1 - \\bar{x}_2}{\\sqrt{\\frac{MSE}{2} \\left(\\frac{1}{n_1} + \\frac{1}{n_2}\\right)}}$
                """,
            distribution: "Studentized range distribution q(k, df) where k = number of groups and df = error degrees of freedom from ANOVA.",
            assumptions: [
                "Data are normally distributed",
                "Equal variances across groups (homoscedasticity)",
                "Independent observations",
                "Approximately equal sample sizes (exact for equal n)"
            ],
            whenToUse: "The standard posthoc test after a significant one-way ANOVA. Tests all k(k\u{2212}1)/2 pairwise comparisons simultaneously while controlling FWER.",
            whenNotToUse: "When comparing only to a control (use Dunnett's). When variances are unequal (use Games-Howell). When data are non-normal (use Dunn's test after Kruskal-Wallis).",
            notes: "Tukey's HSD is the most commonly used posthoc test in biomedical research. It is more powerful than Bonferroni-corrected t-tests because it uses the studentized range distribution, which accounts for the correlation structure of all pairwise differences. Prism uses this as its default posthoc test after ANOVA.",
            references: [
                "Tukey, J.W. (1953). The problem of multiple comparisons. Unpublished manuscript.",
                "Kramer, C.Y. (1956). Extension of multiple range tests to group means with unequal numbers of replications. Biometrics, 12(3), 307\u{2013}310.",
                "Motulsky, H.J. (2014). Intuitive Biostatistics, 4th ed. Oxford. Ch. 37."
            ]
        ),

        StatsTestDetail(
            id: "dunnett",
            name: "Dunnett's Test",
            aliases: ["Dunnett's multiple comparison with control"],
            hypotheses: """
                For each treatment group i vs control:
                $H_0: \\mu_i = \\mu_{\\text{control}}$
                $H_1: \\mu_i \\neq \\mu_{\\text{control}}$
                """,
            testStatistic: """
                $t_i = \\frac{\\bar{x}_i - \\bar{x}_{\\text{control}}}{\\sqrt{MSE \\left(\\frac{1}{n_i} + \\frac{1}{n_{\\text{control}}}\\right)}}$
                # where MSE = mean square error from ANOVA.
                """,
            distribution: "Multivariate t-distribution with special critical values tabulated by Dunnett, accounting for correlation between the k\u{2212}1 comparisons.",
            assumptions: [
                "Data are normally distributed",
                "Equal variances across groups",
                "Independent observations",
                "A designated control group exists"
            ],
            whenToUse: "When comparing k\u{2212}1 treatment groups to a single control. More powerful than Tukey because it makes fewer comparisons.",
            whenNotToUse: "When all pairwise comparisons are of interest (use Tukey). When there is no clear control group.",
            notes: "Dunnett's test is more powerful than Tukey's HSD when only comparisons to a control are needed because it makes k\u{2212}1 comparisons instead of k(k\u{2212}1)/2. Refraction auto-detects a control group when specified in the config.",
            references: [
                "Dunnett, C.W. (1955). A multiple comparison procedure for comparing several treatments with a control. JASA, 50(272), 1096\u{2013}1121.",
                "Motulsky, H.J. (2014). Intuitive Biostatistics, 4th ed. Oxford. Ch. 37."
            ]
        ),

        StatsTestDetail(
            id: "dunn",
            name: "Dunn's Test",
            aliases: ["Dunn's multiple comparison test", "Dunn-Bonferroni"],
            hypotheses: """
                For all pairs (i, j):
                $H_0: \\text{Distributions of groups } i \\text{ and } j \\text{ are identical}$
                $H_1: \\text{Distributions differ}$
                """,
            testStatistic: """
                $z_{ij} = \\frac{\\bar{R}_i - \\bar{R}_j}{\\sqrt{\\frac{N(N+1)}{12} \\left(\\frac{1}{n_i} + \\frac{1}{n_j}\\right)}}$
                # where R-bar_i = mean rank of group i,
                # N = total observations.
                """,
            distribution: "Standard normal distribution (z-test). P-values are then adjusted for multiple comparisons (typically Bonferroni or Holm).",
            assumptions: [
                "Independent observations",
                "Ordinal or continuous data",
                "Significant Kruskal-Wallis test"
            ],
            whenToUse: "Nonparametric posthoc test after a significant Kruskal-Wallis. The standard choice when data violate normality.",
            whenNotToUse: "When data are normally distributed (parametric posthoc tests like Tukey are more powerful).",
            notes: "Dunn's test uses mean ranks rather than raw data, maintaining the nonparametric framework of the Kruskal-Wallis test. The p-values are typically adjusted using Bonferroni or Holm-Bonferroni correction. Refraction applies Holm-Bonferroni by default.",
            references: [
                "Dunn, O.J. (1964). Multiple comparisons using rank sums. Technometrics, 6(3), 241\u{2013}252.",
                "Motulsky, H.J. (2014). Intuitive Biostatistics, 4th ed. Oxford. Ch. 37."
            ]
        ),
    ]
}
