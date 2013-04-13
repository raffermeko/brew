require 'testing_env'
require 'formula'

class FormulaValidationTests < Test::Unit::TestCase
  def formula(*args, &block)
    Class.new(Formula, &block).new(*args)
  end

  def assert_invalid(attr, &block)
    e = assert_raises(FormulaValidationError, &block)
    assert_equal attr, e.attr
  end

  def test_cant_override_brew
    e = assert_raises(RuntimeError) { Class.new(Formula) { def brew; end } }
    assert_equal "You cannot override Formula#brew", e.message
  end

  def test_validates_name
    assert_invalid :name do
      formula "name with spaces" do
        url "foo"
        version "1.0"
      end
    end
  end

  def test_validates_url
    assert_invalid :url do
      formula do
        url ""
        version "1"
      end
    end
  end

  def test_validates_version
    assert_invalid :version do
      formula do
        url "foo"
        version "version with spaces"
      end
    end

    assert_invalid :version do
      formula do
        url "foo"
        version ""
      end
    end
  end

  def test_validates_when_initialize_overridden
    assert_invalid :name do
      formula do
        def initialize; end
      end.brew {}
    end
  end

  def test_devel_only_valid
    assert_nothing_raised do
      formula do
        devel do
          url "foo"
          version "1.0"
        end
      end
    end
  end

  def test_head_only_valid
    assert_nothing_raised do
      formula do
        head "foo"
      end
    end
  end

  def test_empty_formula_invalid
    e = assert_raises(RuntimeError) { formula {} }
    assert_equal "Formulae require at least a URL", e.message
  end
end
