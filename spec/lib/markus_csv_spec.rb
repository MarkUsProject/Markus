require 'rails_helper'

RSpec.describe MarkusCsv do
  describe '.generate' do
    it 'prefixes cells that can be interpreted as formulas and removes tabs' do
      csv = MarkusCsv.generate([['=formula', '-formula', '"formula', '@formula', "+formula\tvalue",
                                 "\t=formula", "text\tvalue"]]) { |row| row }

      expect(CSV.parse(csv)).to eq([[' =formula', ' -formula', ' "formula', ' @formula', ' +formulavalue',
                                     "\t=formula", "text\tvalue"]])
    end

    it 'sanitizes headers as well as data rows' do
      csv = MarkusCsv.generate([['value']], [['=header']]) { |row| row }

      expect(CSV.parse(csv)).to eq([[' =header'], ['value']])
    end

    it 'does not modify ordinary string values' do
      values = ['John Smith', '12345', 'hello@example.com']

      csv = MarkusCsv.generate([values]) { |row| row }

      expect(CSV.parse(csv)).to eq([values])
    end

    it 'preserves nil and non-string values' do
      csv = MarkusCsv.generate([[nil, 123, 1.5, true, false]]) { |row| row }

      expect(CSV.parse(csv)).to eq([[nil, '123', '1.5', 'true', 'false']])
    end

    it 'handles empty headers and rows' do
      csv = MarkusCsv.generate([[]], [[]]) { |row| row }

      expect(CSV.parse(csv)).to eq([[], []])
    end
  end

  describe '.parse' do
    it 'reports short invalid rows in full' do
      result = MarkusCsv.parse("a,b\n") { raise CsvInvalidLineError }

      expect(result[:invalid_lines]).to eq("#{I18n.t('upload_errors.invalid_rows')}a,b")
    end

    it 'truncates long invalid rows' do
      row = Array.new(50) { |i| "value#{i}" }.join(',')
      result = MarkusCsv.parse("#{row}\n") { raise CsvInvalidLineError }

      reported_row = result[:invalid_lines].delete_prefix(I18n.t('upload_errors.invalid_rows'))
      expect(reported_row).to eq(row.truncate(MarkusCsv::MAX_INVALID_LINE_LENGTH))
      expect(reported_row.length).to eq MarkusCsv::MAX_INVALID_LINE_LENGTH
    end

    it 'includes the error message after a truncated row' do
      row = Array.new(50) { |i| "value#{i}" }.join(',')
      result = MarkusCsv.parse("#{row}\n") { raise CsvInvalidLineError, 'some error' }

      expect(result[:invalid_lines]).to end_with('... (some error)')
    end

    it 'reports at most MAX_INVALID_LINES rows' do
      input = Array.new(MarkusCsv::MAX_INVALID_LINES + 5) { |i| "row#{i}" }.join("\n")
      result = MarkusCsv.parse(input) { raise CsvInvalidLineError }

      reported_rows = result[:invalid_lines].delete_prefix(I18n.t('upload_errors.invalid_rows'))
                                            .split(MarkusCsv::INVALID_LINE_SEP)
      expect(reported_rows.length).to eq MarkusCsv::MAX_INVALID_LINES
    end
  end
end
