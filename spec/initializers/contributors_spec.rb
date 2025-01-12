describe Contributors
describe '.read_contributors' do
  subject { Contributors.read_contributors }

  let(:contributors) { ['David Liu', 'Pranav Rao', 'Ivan Chepelev', 'Omid Hemmati'] }

  it 'should return an empty string if the contributors file does not exist' do
    allow(File).to receive(:exist?).and_return(false)
    expect(subject).to eq('')
  end

  it 'should return the contributors if the contributors file exists' do
    allow(File).to receive_messages(
      exist?: true,
      read: contributors.join("\n")
    )
    expect(subject).to eq(contributors.join(', '))
  end
end
