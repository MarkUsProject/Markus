describe AnnotationText do
  context 'checks relationships' do
    it { is_expected.to belong_to(:annotation_category) }
    it { is_expected.to have_many(:annotations) }
    it { is_expected.to belong_to(:creator) }
    it { is_expected.to belong_to(:last_editor) }

    describe '#escape_content' do
      it 'double escapes forward slash' do
        text = create :annotation_text, content: '\\'
        expect(text.escape_content).to eq '\\\\'
      end
      it 'double converts \r\n to \\\n' do
        text = create :annotation_text, content: "\r\n"
        expect(text.escape_content).to eq '\\n'
      end
      it 'double converts \n to \\\n' do
        text = create :annotation_text, content: "\n"
        expect(text.escape_content).to eq '\\n'
      end
      it 'only converts everything in the same string properly' do
        text = create :annotation_text, content: "beginning\nmiddle\r\nmiddle2\\the end"
        expect(text.escape_content).to eq 'beginning\\nmiddle\\nmiddle2\\\\the end'
      end
    end
  end
end
