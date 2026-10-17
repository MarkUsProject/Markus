export function FractionStat({numerator, denominator}) {
  const rounded_numerator = +(Number(numerator) || 0).toFixed(2),
    rounded_denominator = +(Number(denominator) || 0).toFixed(2);
  let result = "0.00";
  if (rounded_denominator !== 0) {
    result = ((Number(numerator) / Number(denominator) || 0) * 100).toFixed(2);
  }
  return (
    <span>
      {rounded_numerator} / {rounded_denominator} ({result}%)
    </span>
  );
}
