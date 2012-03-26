require "spec_helper.rb"

describe DiffBase do
  context "#supported" do
    subject { DiffBase.supported }
    it { should == "*.*" }
  end

  context "#diff" do
    let(:file) { "tmp/text.txt" }
    let(:text) { "text" }
    before do
      @diff = DiffBase.new
      FileUtils.mkdir_p("tmp")
      File.open(file, "w+") { |f| f.write(text) }
    end

    after do
      File.unlink(file)
      FileUtils.rmdir("tmp")
    end

    context "new file given" do
      subject { @diff.diff(file, nil)[0] }
      its(:file) { should  == file }
      its(:diff) { should == { add: text, delete: nil } }
      its(:change_mode) { should == :create }
      its(:diff_class) { should == :DiffBase }
    end

    context "not changed file given" do
      subject { @diff.diff(file, text)[0] }
      its(:file) { should  == file }
      its(:diff) { should == { add: "", delete: "" } }
      its(:change_mode) { should == :none }
      its(:diff_class) { should == :DiffBase }
    end

    context "changed file given" do
      let(:changed) { "changed" }
      before do
        File.open(file, "w") { |f| f.write(changed) }
      end

      subject { @diff.diff(file, text)[0] }
      its(:file) { should  == file }
      its(:diff) { should == { add: changed, delete: text } }
      its(:change_mode) { should == :change }
      its(:diff_class) { should == :DiffBase }
    end

    context "null file given" do
      before do
        FakeFS.deactivate!
      end

      after do
        FakeFS.activate!
      end

      subject { @diff.diff(DiffBase::NULL_FILE, text)[0] }
      its(:file) { should  == DiffBase::NULL_FILE }
      its(:diff) { should == { add: nil, delete: text } }
      its(:change_mode) { should == :remove }
      its(:diff_class) { should == :DiffBase }
    end
  end

  context "#apply" do
    let(:file) { "tmp/text.txt" }
    let(:text) { "text" }
    let(:changed) { "changed" }
    before do
      @diff = DiffBase.new
    end

    context "other than remove mode hunk given" do
      let(:hunks) do
        [
          Hunk.new(file, { add: text, delete: nil }, :create, :DiffBase),
          Hunk.new(file, { add: changed, delete: text }, :change, :DiffBase),
          Hunk.new(file, { add: "", delete: "" }, :none, :DiffBase)
        ]
      end

      context ":forward given" do
        subject { @diff.apply(nil, hunks, :forward) }
        it { should == changed }
      end

      context ":inverse given" do
        subject { @diff.apply(changed, hunks, :inverse) }
        it { should == nil }
      end
    end

    context "all change mode hunk given" do
      let(:hunks) do
        [
          Hunk.new(file, { add: text, delete: nil }, :create, :DiffBase),
          Hunk.new(file, { add: changed, delete: text }, :change, :DiffBase),
          Hunk.new(file, { add: "", delete: "" }, :none, :DiffBase),
          Hunk.new(file, { add: nil, delete: changed }, :remove, :DiffBase)
        ]
      end

      context ":forward given" do
        subject { @diff.apply(nil, hunks, :forward) }
        it { should == nil }
      end

      context ":inverse given" do
        subject { @diff.apply(changed, hunks, :inverse) }
        it { should == nil }
      end
    end
  end
end
