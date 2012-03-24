require "spec_helper.rb"

describe DiffCreator do
  before do
    FileUtils.mkdir_p("plugin/diff")
    File.open("plugin/diff/text_diff.rb", "w+") do |f|
      f.write(%q|
class TextDiff < DiffBase
  def self.supported
    ".txt"
  end
end
              |)
    end
    File.open("plugin/diff/rb_diff.rb", "w+") do |f|
      f.write(%q|
class RubyDiff < DiffBase
  def self.supported
    ".rb"
  end
end
              |)
    end

    @creator = DiffCreator.new
  end

  context "#create" do
    context "unknown extention given" do
      let(:extention) { ".tmp" }
      subject { @creator.create(extention) }
      its(:class) { should == DiffBase }
    end

    context ".txt given" do
      let(:extention) { ".txt" }
      subject { @creator.create(extention).class }
      its(:supported) { should == extention }
    end
  end

  context "#create_by_name" do
    context "unknown class name given" do
      let(:name) { "UnknownDiff" }
      specify { expect { @creator.create_by_name(name) }.to raise_error(NameError) }
    end

    context "TextDiff given" do
      let(:name) { "TextDiff" }
      subject { @creator.create_by_name(name).class }
      its(:supported) { should == ".txt" }
    end

    context "DiffBase given" do
      let(:name) { "DiffBase" }
      subject { @creator.create_by_name(name) }
      its(:class) { should == DiffBase }
    end
  end

  context "#get_classes" do
    subject { @creator.get_classes }
    its(:count) { should == 2 }
  end
end
