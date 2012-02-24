require 'test/unit'
require File.expand_path('../../lib/supply_drop/syntax_checker', __FILE__)

class SyntaxCheckerTest < Test::Unit::TestCase

  def test_syntax_checks_puppet_files
    checker = SupplyDrop::SyntaxChecker.new(File.expand_path('../files', __FILE__))
    errors = checker.validate_puppet_files
    assert_equal 1, errors.count
    file, error = errors.first
    assert_match %r[manifests/invalid.pp$], file
    assert_match %r[expected '\}'], error
  end

  def test_synatx_checks_erb_files
    checker = SupplyDrop::SyntaxChecker.new(File.expand_path('../files', __FILE__))
    errors = checker.validate_templates
    assert_equal 1, errors.count
    file, error = errors.first
    assert_match %r[templates/invalid.erb$], file
    assert_match %r[syntax error], error
  end
end
