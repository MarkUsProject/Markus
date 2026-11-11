require 'rails_helper'

RSpec.describe MarkusCsv do
  describe '.generate' do
    it 'prefixes cells that can be interpreted as formulas and removes tabs' do
      csv = MarkusCsv.generate([['=formula', '-formula', '"formula', '@formula', '+formula',
                                 "\t=formula", "text\tvalue"]]) { |row| row }

      expect(CSV.parse(csv)).to eq([[' =formula', ' -formula', ' "formula', ' @formula', ' +formula',
                                     ' =formula', 'textvalue']])
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
  end
end
