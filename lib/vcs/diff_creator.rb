class DiffCreator
  def initialize
    @m = Module.new
    Dir.glob("plugin/diff/*.rb").each do |p|
      File.open(p) do |f|
        @m.module_eval f.read
      end
    end

    @extention = {}
    get_classes.each do |c|
      @extention[c.supported] = c
    end
  end

  def get_classes
    [].tap do |a|
      @m.constants.each do |c|
        const = @m.const_get(c.to_s)
        if const.kind_of?(Class) && const.superclass == DiffBase
          a << const
        end
      end
    end
  end

  def create(extention)
    if @extention[extention]
      @extention[extention].new
    else
      DiffBase.new
    end
  end

  def create_by_name(name)
    @m.const_get(name.to_s).new
  end
end
