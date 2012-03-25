require "spec_helper.rb"

describe Index do
  context "#initialize" do
    let(:project_path) { "test/project" }
    let(:file) { "tmp/text.txt" }
    let(:text) { "text" }
    let(:changed) { "changed" }
    let(:hash) { { file => Digest::SHA1.digest(changed) } }
    let(:data) { { file => text } }
    let(:hunks) { [Hunk.new(file, { add: changed, delete: text }, :change, :DiffBase)] }

    before do
      FileUtils.mkdir_p(project_path)
      @index = Index.new(project_path)
      @index.hash = hash
      @index.data = data
      @index.hunks = hunks
      @index.save_index
    end

    subject { Index.new(project_path) }
    its(:hash) { should == hash }
    its(:data) { should == data }
    its("hunks.length") { should == hunks.length }
  end
end
