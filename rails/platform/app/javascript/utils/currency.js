// 通貨フォーマット用ユーティリティ

/**
 * 金額を日本円フォーマットで表示
 * @param {number} amount - 金額
 * @param {boolean} round - 四捨五入するか（デフォルト: true）
 * @returns {string} フォーマットされた金額文字列
 */
export function formatCurrency(amount, round = true) {
  const value = round ? Math.round(amount) : amount
  return "¥" + value.toLocaleString("ja-JP")
}

/**
 * 金額文字列から数値を抽出
 * @param {string} str - 金額文字列（例: "¥1,234,567"）
 * @returns {number} 数値
 */
export function parseCurrency(str) {
  if (typeof str === "number") return str
  return parseFloat(str.replace(/[¥,]/g, "")) || 0
}
