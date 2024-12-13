module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
  ],
  rules: {
    indent: ["error", 4],
    quotes: ["error", "double"],
    "object-curly-spacing": ["error", "never"],
    "max-len": ["error", {code: 120}],
  },
  parserOptions: {
    ecmaVersion: 2020,
  },
};
