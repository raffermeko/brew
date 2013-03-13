class Compilers
  include Enumerable

  def initialize(*args)
    @compilers = Array.new(*args)
  end

  def each(*args, &block)
    @compilers.each(*args, &block)
  end

  def include?(cc)
    cc = cc.name if cc.is_a? Compiler
    @compilers.any? { |c| c.name == cc }
  end

  def <<(o)
    @compilers << o
    self
  end
end


class Compiler
  attr_reader :name, :build

  def initialize name
    @name = name
    @build = case name
    when :clang then MacOS.clang_build_version.to_i
    when :llvm then MacOS.llvm_build_version.to_i
    when :gcc then MacOS.gcc_42_build_version.to_i
    end
  end

  def ==(other)
    @name.to_sym == other.to_sym
  end
end


class CompilerFailure
  attr_reader :compiler

  def initialize compiler, &block
    @compiler = compiler
    instance_eval(&block) if block_given?
    @build ||= 9999
  end

  def build val=nil
    val.nil? ? @build.to_i : @build = val.to_i
  end

  def cause val=nil
    val.nil? ? @cause : @cause = val
  end
end


# CompilerSelector is used to process a formula's CompilerFailures.
# If no viable compilers are available, ENV.compiler is left as-is.
class CompilerSelector
  NAMES = { :clang => "Clang", :gcc => "GCC", :llvm => "LLVM" }

  def initialize f
    @f = f
    @old_compiler = ENV.compiler
    @compilers = Compilers.new
    @compilers << Compiler.new(:clang) if MacOS.clang_build_version
    @compilers << Compiler.new(:llvm) if MacOS.llvm_build_version
    @compilers << Compiler.new(:gcc) if MacOS.gcc_42_build_version
  end

  def select_compiler
    # @compilers is our list of available compilers. If @f declares a
    # failure with compiler foo, then we remove foo from the list if
    # the failing build is >= the currently installed version of foo.
    @compilers = @compilers.reject do |cc|
      failure = @f.fails_with? cc
      failure && failure.build >= cc.build
    end

    return if @compilers.empty? or @compilers.include? ENV.compiler

    ENV.send case ENV.compiler
    when :clang
      if @compilers.include? :llvm then :llvm
      elsif @compilers.include? :gcc then :gcc
      else ENV.compiler
      end
    when :llvm
      if @compilers.include? :clang and MacOS.clang_build_version >= 211 then :clang
      elsif @compilers.include? :gcc then :gcc
      elsif @compilers.include? :clang then :clang
      else ENV.compiler
      end
    when :gcc
      if @compilers.include? :clang and MacOS.clang_build_version >= 211 then :clang
      elsif @compilers.include? :llvm then :llvm
      elsif @compilers.include? :clang then :clang
      else ENV.compiler
      end
    end
  end
end
