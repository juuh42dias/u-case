require 'test_helper'

class Micro::Service::SafeTest < Minitest::Test
  class Divide < Micro::Service::Safe
    attributes :a, :b

    def call!
      if a.is_a?(Integer) && b.is_a?(Integer)
        Success(a / b)
      else
        Failure(:not_an_integer)
      end
    end
  end

  def test_instance_call_method
    result = Divide.new(a: 2, b: 2).call

    assert(result.success?)
    assert_equal(1, result.value)
    assert_kind_of(Micro::Service::Result, result)

    # ---

    result = Divide.new(a: 2.0, b: 2).call

    assert(result.failure?)
    assert_equal(:not_an_integer, result.value)
    assert_kind_of(Micro::Service::Result, result)
  end

  def test_class_call_method
    result = Divide.call(a: 2, b: 2)

    assert(result.success?)
    assert_equal(1, result.value)
    assert_kind_of(Micro::Service::Result, result)

    # ---

    result = Divide.call(a: 2.0, b: 2)

    assert(result.failure?)
    assert_equal(:not_an_integer, result.value)
    assert_kind_of(Micro::Service::Result, result)
  end

  class Foo < Micro::Service::Safe
  end

  def test_template_method
    assert_raises(NotImplementedError) { Micro::Service::Safe.call }
    assert_raises(NotImplementedError) { Micro::Service::Safe.new({}).call }

    assert_raises(NotImplementedError) { Foo.call }
    assert_raises(NotImplementedError) { Foo.new({}).call }
  end

  class LoremIpsum < Micro::Service::Safe
    attributes :text

    def call!
      text
    end
  end

  def test_result_error
    err1 = assert_raises(TypeError) { LoremIpsum.call(text: 'lorem ipsum') }
    assert_equal('Micro::Service::SafeTest::LoremIpsum#call! must return an instance of Micro::Service::Result', err1.message)

    err2 = assert_raises(TypeError) { LoremIpsum.new(text: 'ipsum indolor').call }
    assert_equal('Micro::Service::SafeTest::LoremIpsum#call! must return an instance of Micro::Service::Result', err2.message)
  end

  def test_that_exceptions_generate_a_failure
    result_1 = Divide.new(a: 2, b: 0).call

    assert(result_1.failure?)
    assert_instance_of(ZeroDivisionError, result_1.value)
    assert_kind_of(Micro::Service::Result, result_1)

    counter_1 = 0

    result_1
      .on_failure { counter_1 += 1 }
      .on_failure(:exception) { |value| counter_1 += 1 if value.is_a?(ZeroDivisionError) }
      .on_failure(:exception) { |_value, service| counter_1 += 1 if service.is_a?(Divide) }

    assert_equal(3, counter_1)

    # ---

    result_2 = Divide.call(a: 2, b: 0)

    assert(result_2.failure?)
    assert_instance_of(ZeroDivisionError, result_2.value)
    assert_kind_of(Micro::Service::Result, result_2)

    counter_2 = 0

    result_2
      .on_failure { counter_2 += 1 }
      .on_failure(:exception) { |value| counter_2 += 1 if value.is_a?(ZeroDivisionError) }
      .on_failure(:exception) { |_value, service| counter_2 += 1 if service.is_a?(Divide) }

    assert_equal(3, counter_2)
  end
end
