// @ts-nocheck
import typescriptEslint from "@typescript-eslint/eslint-plugin"
import tsParser from "@typescript-eslint/parser"
import eslintJs from "@eslint/js"
import globals from "globals"

export default [
    // Apply ESLint's recommended base JS rules first
    eslintJs.configs.recommended,

    {
        files: ["**/*.js", "**/*.jsx", "**/*.ts", "**/*.tsx"],

        languageOptions: {
            globals: {
                ...globals.mocha,
                ...globals.node,
            },
            parser: tsParser,
            parserOptions: {
                ecmaVersion: "ESNext",
                sourceType: "module",
                project: true,
            },
        },

        plugins: {
            "@typescript-eslint": typescriptEslint,
        },

        rules: {
            /* =====================
             * Base ESLint Rules
             * ===================== */
            "curly": ["error", "all"],
            "eqeqeq": ["error", "always"],
            "no-throw-literal": "error",
            "semi": ["error", "always"],
            "quotes": ["error", "double", { avoidEscape: true }],
            "comma-dangle": ["error", "always-multiline"],
            "no-console": ["warn", { allow: ["warn", "error"] }],
            "no-debugger": "error",
            "no-var": "error",
            "prefer-const": "error",
            "no-unused-vars": "off", // handled by TS rule below
            "no-multiple-empty-lines": ["error", { max: 1 }],
            "object-curly-spacing": ["error", "always"],
            "array-bracket-spacing": ["error", "never"],
            "space-before-blocks": ["error", "always"],
            "keyword-spacing": ["error", { before: true, after: true }],
            "arrow-spacing": ["error", { before: true, after: true }],

            /* =====================
             * TypeScript Rules
             * ===================== */
            ...typescriptEslint.configs["strict"].rules, // enable all strict TS rules

            "@typescript-eslint/naming-convention": [
                "error",
                // Variables
                {
                    selector: "variableLike",
                    format: ["camelCase", "PascalCase", "UPPER_CASE"],
                    leadingUnderscore: "allow",
                },
                // Types and Interfaces
                {
                    selector: "typeLike",
                    format: ["PascalCase"],
                },
                // Enums
                {
                    selector: "enumMember",
                    format: ["PascalCase"],
                },
                // Imports
                {
                    selector: "import",
                    format: ["camelCase", "PascalCase"],
                },
            ],

            "@typescript-eslint/explicit-function-return-type": [
                "error",
                { allowExpressions: false },
            ],
            "@typescript-eslint/no-explicit-any": "error",
            "@typescript-eslint/no-inferrable-types": "error",
            "@typescript-eslint/consistent-type-imports": [
                "error",
                { prefer: "type-imports" },
            ],
            "@typescript-eslint/no-non-null-assertion": "error",
            "@typescript-eslint/no-unused-vars": [
                "error",
                { argsIgnorePattern: "^_", varsIgnorePattern: "^_" },
            ],
            "@typescript-eslint/no-floating-promises": "error",
            "@typescript-eslint/array-type": ["error", { default: "array-simple" }],
            "@typescript-eslint/consistent-type-assertions": [
                "error",
                { assertionStyle: "as", objectLiteralTypeAssertions: "never" },
            ],
            "@typescript-eslint/consistent-type-definitions": ["error", "interface"],
            "@typescript-eslint/method-signature-style": ["error", "method"],
            "@typescript-eslint/strict-boolean-expressions": "error",
            "@typescript-eslint/switch-exhaustiveness-check": "error",
            "@typescript-eslint/prefer-readonly": "error",
            "@typescript-eslint/prefer-for-of": "error",
            "@typescript-eslint/unified-signatures": "error",
            "@typescript-eslint/no-require-imports": "error",
            "@typescript-eslint/no-namespace": "error",
            "@typescript-eslint/prefer-as-const": "error",

            /* =====================
             * Style & Complexity
             * ===================== */
            "max-lines": ["warn", { max: 300, skipBlankLines: true, skipComments: true }],
            "max-depth": ["error", 4],
            "max-params": ["error", 5],
            "complexity": ["error", 10],
            "max-statements": ["warn", 30],
            "no-trailing-spaces": "error",
            "eol-last": ["error", "always"],
        },
    },
]
