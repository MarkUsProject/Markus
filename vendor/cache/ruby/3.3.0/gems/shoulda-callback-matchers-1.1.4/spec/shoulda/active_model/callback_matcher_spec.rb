  require 'spec_helper'

describe Shoulda::Callback::Matchers::ActiveModel do

  context "invalid use" do
    before do
      @callback_object_class = define_model :callback do
          define_method("before_create"){}
          define_method("after_save"){}
      end
      callback_object = @callback_object_class.new
      @model = define_model(:example, :attr  => :string,
                                      :other => :integer) do
        before_create :dance!, :if => :evaluates_to_false!
        after_save  :shake!, :unless => :evaluates_to_true!
        after_create :wiggle!
        before_create callback_object, :if => :evaluates_to_false!
        after_save  callback_object, :unless => :evaluates_to_true!
        after_create callback_object
        define_method(:shake!){}
        define_method(:dance!){}
      end.new

    end
    it "should return a meaningful error when used without a defined lifecycle" do
      expect { callback(:dance!).matches? :foo }.to raise_error Shoulda::Callback::Matchers::ActiveModel::UsageError,
        "callback dance! can not be tested against an undefined lifecycle, use .before, .after or .around"
    end
    it "should return a meaningful error when used with an optional lifecycle without the original lifecycle being validation" do
      expect { callback(:dance!).after(:create).on(:save) }.to raise_error Shoulda::Callback::Matchers::ActiveModel::UsageError,
        "The .on option is only valid for validation, commit, and rollback and cannot be used with create, use with .before(:validation) or .after(:validation)"
    end
    it "should return a meaningful error when used without a defined lifecycle" do
      expect { callback(@callback_object_class).matches? :foo }.to raise_error Shoulda::Callback::Matchers::ActiveModel::UsageError,
        "callback Callback can not be tested against an undefined lifecycle, use .before, .after or .around"
    end
    it "should return a meaningful error when used with an optional lifecycle without the original lifecycle being validation" do
      expect { callback(@callback_object_class).after(:create).on(:save) }.to raise_error Shoulda::Callback::Matchers::ActiveModel::UsageError,
        "The .on option is only valid for validation, commit, and rollback and cannot be used with create, use with .before(:validation) or .after(:validation)"
    end
    it "should return a meaningful error when used with rollback or commit and before" do
      expect { callback(@callback_object_class).before(:commit).on(:destroy) }.to raise_error Shoulda::Callback::Matchers::ActiveModel::UsageError,
        "Can not callback before or around commit, use after."
    end
  end

  [:save, :create, :update, :destroy].each do |lifecycle|
    context "on #{lifecycle}" do
      before do
        @callback_object_class = define_model(:callback) do
          define_method("before_#{lifecycle}"){}
          define_method("after_#{lifecycle}"){}
          define_method("around_#{lifecycle}"){}
        end

        callback_object = @callback_object_class.new

        @other_callback_object_class = define_model(:other_callback) do
          define_method("after_#{lifecycle}"){}
          define_method("around_#{lifecycle}"){}
        end

        other_callback_object = @other_callback_object_class.new

        @callback_object_not_found_class = define_model(:callback_not_found) do
          define_method("before_#{lifecycle}"){}
          define_method("after_#{lifecycle}"){}
          define_method("around_#{lifecycle}"){}
        end

        @model = define_model(:example, :attr  => :string,
                                        :other => :integer) do
          send(:"before_#{lifecycle}", :dance!, :if => :evaluates_to_false!)
          send(:"after_#{lifecycle}", :shake!, :unless => :evaluates_to_true!)
          send(:"around_#{lifecycle}", :giggle!)
          send(:"before_#{lifecycle}", :wiggle!)

          send(:"before_#{lifecycle}", callback_object, :if => :evaluates_to_false!)
          send(:"after_#{lifecycle}", callback_object, :unless => :evaluates_to_true!)
          send(:"around_#{lifecycle}", callback_object)
          send(:"before_#{lifecycle}", other_callback_object)

          define_method(:shake!){}
          define_method(:dance!){}
          define_method(:giggle!){}
        end.new
      end
      context "as a simple callback test" do
        it "should find the callback before the fact" do
          expect(@model).to callback(:dance!).before(lifecycle)
        end
        it "should find the callback after the fact" do
          expect(@model).to callback(:shake!).after(lifecycle)
        end
        it "should find the callback around the fact" do
          expect(@model).to callback(:giggle!).around(lifecycle)
        end
        it "should not find callbacks that are not there" do
          expect(@model).not_to callback(:scream!).around(lifecycle)
        end
        it "should not find callback_objects around the fact" do
          expect(@model).not_to callback(:shake!).around(lifecycle)
        end
        it "should have a meaningful description" do
          matcher = callback(:dance!).before(lifecycle)
          expect(matcher.description).to eq("callback dance! before #{lifecycle}")
        end
        it "should find the callback_object before the fact" do
          expect(@model).to callback(@callback_object_class).before(lifecycle)
        end
        it "should find the callback_object after the fact" do
          expect(@model).to callback(@callback_object_class).after(lifecycle)
        end
        it "should find the callback_object around the fact" do
          expect(@model).to callback(@callback_object_class).around(lifecycle)
        end
        it "should not find callbacks that are not there" do
          expect(@model).not_to callback(@callback_object_not_found_class).around(lifecycle)
        end
        it "should not find callback_objects around the fact" do
          expect(@model).not_to callback(@callback_object_not_found_class).around(lifecycle)
        end
        it "should have a meaningful description" do
          matcher = callback(@callback_object_class).before(lifecycle)
          expect(matcher.description).to eq("callback Callback before #{lifecycle}")
        end
        it "should have a meaningful error if it fails with an inexistent method on a model" do
          matcher = callback(:wiggle!).before(lifecycle)
          expect(matcher.matches?(@model)).to eq(false)
          expect(matcher.failure_message).to eq("callback wiggle! is listed as a callback before #{lifecycle}, but the model does not respond to wiggle! (using respond_to?(:wiggle!, true)")
        end
        it "should have a meaningful error if it fails with an inexistent method on a callback class" do
          matcher = callback(@other_callback_object_class).before(lifecycle)
          expect(matcher.matches?(@model)).to eq(false)
          expect(matcher.failure_message).to eq("callback OtherCallback is listed as a callback before #{lifecycle}, but the given object does not respond to before_#{lifecycle} (using respond_to?(:before_#{lifecycle}, true)")
        end
      end
      context "with conditions" do
        it "should match the if condition" do
          expect(@model).to callback(:dance!).before(lifecycle).if(:evaluates_to_false!)
        end
        it "should match the unless condition" do
          expect(@model).to callback(:shake!).after(lifecycle).unless(:evaluates_to_true!)
        end
        it "should not find callbacks not matching the conditions" do
          expect(@model).not_to callback(:giggle!).around(lifecycle).unless(:evaluates_to_false!)
        end
        it "should not find callbacks that are not there entirely" do
          expect(@model).not_to callback(:scream!).before(lifecycle).unless(:evaluates_to_false!)
        end
        it "should have a meaningful description" do
          matcher = callback(:dance!).after(lifecycle).unless(:evaluates_to_false!)
          expect(matcher.description).to eq("callback dance! after #{lifecycle} unless evaluates_to_false! evaluates to false")
        end

        it "should match the if condition" do
          expect(@model).to callback(@callback_object_class).before(lifecycle).if(:evaluates_to_false!)
        end
        it "should match the unless condition" do
          expect(@model).to callback(@callback_object_class).after(lifecycle).unless(:evaluates_to_true!)
        end
        it "should not find callbacks not matching the conditions" do
          expect(@model).not_to callback(@callback_object_class).around(lifecycle).unless(:evaluates_to_false!)
        end
        it "should not find callbacks that are not there entirely" do
          expect(@model).not_to callback(@callback_object_not_found_class).before(lifecycle).unless(:evaluates_to_false!)
        end
        it "should have a meaningful description" do
          matcher = callback(@callback_object_class).after(lifecycle).unless(:evaluates_to_false!)
          expect(matcher.description).to eq("callback Callback after #{lifecycle} unless evaluates_to_false! evaluates to false")
        end
      end
    end
  end

  context "on validation" do
    before do
     @callback_object_class = define_model(:callback) do
        define_method("before_validation"){}
        define_method("after_validation"){}
      end

      @callback_object_class2 = define_model(:callback2) do
        define_method("before_validation"){}
        define_method("after_validation"){}
      end

      callback_object = @callback_object_class.new
      callback_object2 = @callback_object_class2.new

      @callback_object_not_found_class = define_model(:callback_not_found) do
        define_method("before_validation"){}
        define_method("after_validation"){}
      end
      @model = define_model(:example, :attr  => :string,
                                      :other => :integer) do
        before_validation :dance!, :if => :evaluates_to_false!
        after_validation  :shake!, :unless => :evaluates_to_true!
        before_validation :dress!, :on => :create
        after_validation  :shriek!, :on => :update, :unless => :evaluates_to_true!
        after_validation  :pucker!, :on => :save, :if => :evaluates_to_false!
        before_validation callback_object, :if => :evaluates_to_false!
        after_validation  callback_object, :unless => :evaluates_to_true!
        before_validation callback_object, :on => :create
        after_validation  callback_object, :on => :update, :unless => :evaluates_to_true!
        after_validation  callback_object2, :on => :save, :if => :evaluates_to_false!
        define_method(:dance!){}
        define_method(:shake!){}
        define_method(:dress!){}
        define_method(:shriek!){}
        define_method(:pucker!){}
      end.new
    end

    context "as a simple callback test" do
      it "should find the callback before the fact" do
        expect(@model).to callback(:dance!).before(:validation)
      end
      it "should find the callback after the fact" do
        expect(@model).to callback(:shake!).after(:validation)
      end
      it "should not find a callback around the fact" do
        expect(@model).not_to callback(:giggle!).around(:validation)
      end
      it "should not find callbacks that are not there" do
        expect(@model).not_to callback(:scream!).around(:validation)
      end
      it "should have a meaningful description" do
        matcher = callback(:dance!).before(:validation)
        expect(matcher.description).to eq("callback dance! before validation")
      end

      it "should find the callback before the fact" do
        expect(@model).to callback(@callback_object_class).before(:validation)
      end
      it "should find the callback after the fact" do
        expect(@model).to callback(@callback_object_class).after(:validation)
      end
      it "should not find a callback around the fact" do
        expect(@model).not_to callback(@callback_object_class).around(:validation)
      end
      it "should not find callbacks that are not there" do
        expect(@model).not_to callback(@callback_object_not_found_class).around(:validation)
      end
      it "should have a meaningful description" do
        matcher = callback(@callback_object_class).before(:validation)
        expect(matcher.description).to eq("callback Callback before validation")
      end
    end

    context "with additinal lifecycles defined" do
      it "should find the callback before the fact on create" do
        expect(@model).to callback(:dress!).before(:validation).on(:create)
      end
      it "should find the callback after the fact on update" do
        expect(@model).to callback(:shriek!).after(:validation).on(:update)
      end
      it "should find the callback after the fact on save" do
        expect(@model).to callback(:pucker!).after(:validation).on(:save)
      end
      it "should not find a callback for pucker! after the fact on update" do
        expect(@model).not_to callback(:pucker!).after(:validation).on(:update)
      end
      it "should have a meaningful description" do
        matcher = callback(:dance!).after(:validation).on(:update)
        expect(matcher.description).to eq("callback dance! after validation on update")
      end

      it "should find the callback before the fact on create" do
        expect(@model).to callback(@callback_object_class).before(:validation).on(:create)
      end
      it "should find the callback after the fact on update" do
        expect(@model).to callback(@callback_object_class).after(:validation).on(:update)
      end
      it "should find the callback after the fact on save" do
        expect(@model).to callback(@callback_object_class2).after(:validation).on(:save)
      end
      it "should not find a callback for Callback after the fact on update" do
        expect(@model).not_to callback(@callback_object_class2).after(:validation).on(:update)
      end
      it "should have a meaningful description" do
        matcher = callback(@callback_object_class).after(:validation).on(:update)
        expect(matcher.description).to eq("callback Callback after validation on update")
      end
    end

    context "with conditions" do
      it "should match the if condition" do
        expect(@model).to callback(:dance!).before(:validation).if(:evaluates_to_false!)
      end
      it "should match the unless condition" do
        expect(@model).to callback(:shake!).after(:validation).unless(:evaluates_to_true!)
      end
      it "should not find callbacks not matching the conditions" do
        expect(@model).not_to callback(:giggle!).around(:validation).unless(:evaluates_to_false!)
      end
      it "should not find callbacks that are not there entirely" do
        expect(@model).not_to callback(:scream!).before(:validation).unless(:evaluates_to_false!)
      end
      it "should have a meaningful description" do
        matcher = callback(:dance!).after(:validation).unless(:evaluates_to_false!)
        expect(matcher.description).to eq("callback dance! after validation unless evaluates_to_false! evaluates to false")
      end

      it "should match the if condition" do
        expect(@model).to callback(@callback_object_class).before(:validation).if(:evaluates_to_false!)
      end
      it "should match the unless condition" do
        expect(@model).to callback(@callback_object_class).after(:validation).unless(:evaluates_to_true!)
      end
      it "should not find callbacks not matching the conditions" do
        expect(@model).not_to callback(@callback_object_class).around(:validation).unless(:evaluates_to_false!)
      end
      it "should not find callbacks that are not there entirely" do
        expect(@model).not_to callback(@callback_object_not_found_class).before(:validation).unless(:evaluates_to_false!)
      end
      it "should have a meaningful description" do
        matcher = callback(@callback_object_class).after(:validation).unless(:evaluates_to_false!)
        expect(matcher.description).to eq("callback Callback after validation unless evaluates_to_false! evaluates to false")
      end
    end

    context "with conditions and additional lifecycles" do
      it "should find the callback before the fact on create" do
        expect(@model).to callback(:dress!).before(:validation).on(:create)
      end
      it "should find the callback after the fact on update with the unless condition" do
        expect(@model).to callback(:shriek!).after(:validation).on(:update).unless(:evaluates_to_true!)
      end
      it "should find the callback after the fact on save with the if condition" do
        expect(@model).to callback(:pucker!).after(:validation).on(:save).if(:evaluates_to_false!)
      end
      it "should not find a callback for pucker! after the fact on save with the wrong condition" do
        expect(@model).not_to callback(:pucker!).after(:validation).on(:save).unless(:evaluates_to_false!)
      end
      it "should have a meaningful description" do
        matcher = callback(:dance!).after(:validation).on(:save).unless(:evaluates_to_false!)
        expect(matcher.description).to eq("callback dance! after validation on save unless evaluates_to_false! evaluates to false")
      end

      it "should find the callback before the fact on create" do
        expect(@model).to callback(@callback_object_class).before(:validation).on(:create)
      end
      it "should find the callback after the fact on update with the unless condition" do
        expect(@model).to callback(@callback_object_class).after(:validation).on(:update).unless(:evaluates_to_true!)
      end
      it "should find the callback after the fact on save with the if condition" do
        expect(@model).to callback(@callback_object_class2).after(:validation).on(:save).if(:evaluates_to_false!)
      end
      it "should not find a callback for Callback after the fact on save with the wrong condition" do
        expect(@model).not_to callback(@callback_object_class).after(:validation).on(:save).unless(:evaluates_to_false!)
      end
      it "should have a meaningful description" do
        matcher = callback(@callback_object_class).after(:validation).on(:save).unless(:evaluates_to_false!)
        expect(matcher.description).to eq("callback Callback after validation on save unless evaluates_to_false! evaluates to false")
      end
    end
  end


  [:rollback, :commit].each do |lifecycle|
    context "on #{lifecycle}" do
      before do
       @callback_object_class = define_model(:callback) do
          define_method("after_#{lifecycle}"){}
        end

        @callback_object_class2 = define_model(:callback2) do
          define_method("after_#{lifecycle}"){}
        end

        callback_object = @callback_object_class.new
        callback_object2 = @callback_object_class2.new

        @callback_object_not_found_class = define_model(:callback_not_found) do
          define_method("after_#{lifecycle}"){}
        end
        @model = define_model(:example, :attr  => :string,
                                        :other => :integer) do
          send :"after_#{lifecycle}", :dance!, :if => :evaluates_to_false!
          send :"after_#{lifecycle}", :shake!, :unless => :evaluates_to_true!
          send :"after_#{lifecycle}", :dress!, :on => :create
          send :"after_#{lifecycle}", :shriek!, :on => :update, :unless => :evaluates_to_true!
          send :"after_#{lifecycle}", :pucker!, :on => :destroy, :if => :evaluates_to_false!
          send :"after_#{lifecycle}", callback_object, :if => :evaluates_to_false!
          send :"after_#{lifecycle}", callback_object, :unless => :evaluates_to_true!
          send :"after_#{lifecycle}", callback_object, :on => :create
          send :"after_#{lifecycle}", callback_object, :on => :update, :unless => :evaluates_to_true!
          send :"after_#{lifecycle}", callback_object2, :on => :destroy, :if => :evaluates_to_false!
          define_method(:dance!){}
          define_method(:shake!){}
          define_method(:dress!){}
          define_method(:shriek!){}
          define_method(:pucker!){}
        end.new
      end

      context "as a simple callback test" do
        it "should find the callback after the fact" do
          expect(@model).to callback(:shake!).after(lifecycle)
        end
        it "should not find callbacks that are not there" do
          expect(@model).not_to callback(:scream!).after(lifecycle)
        end
        it "should have a meaningful description" do
          matcher = callback(:dance!).after(lifecycle)
          expect(matcher.description).to eq("callback dance! after #{lifecycle}")
        end

        it "should find the callback after the fact" do
          expect(@model).to callback(@callback_object_class).after(lifecycle)
        end
        it "should not find callbacks that are not there" do
          expect(@model).not_to callback(@callback_object_not_found_class).after(lifecycle)
        end
        it "should have a meaningful description" do
          matcher = callback(@callback_object_class).after(lifecycle)
          expect(matcher.description).to eq("callback Callback after #{lifecycle}")
        end
      end

      context "with additinal lifecycles defined" do
        it "should find the callback after the fact on create" do
          expect(@model).to callback(:dress!).after(lifecycle).on(:create)
        end
        it "should find the callback after the fact on update" do
          expect(@model).to callback(:shriek!).after(lifecycle).on(:update)
        end
        it "should find the callback after the fact on save" do
          expect(@model).to callback(:pucker!).after(lifecycle).on(:destroy)
        end
        it "should not find a callback for pucker! after the fact on update" do
          expect(@model).not_to callback(:pucker!).after(lifecycle).on(:update)
        end
        it "should have a meaningful description" do
          matcher = callback(:dance!).after(lifecycle).on(:update)
          expect(matcher.description).to eq("callback dance! after #{lifecycle} on update")
        end

        it "should find the callback before the fact on create" do
          expect(@model).to callback(@callback_object_class).after(lifecycle).on(:create)
        end
        it "should find the callback after the fact on update" do
          expect(@model).to callback(@callback_object_class).after(lifecycle).on(:update)
        end
        it "should find the callback after the fact on save" do
          expect(@model).to callback(@callback_object_class2).after(lifecycle).on(:destroy)
        end
        it "should not find a callback for Callback after the fact on update" do
          expect(@model).not_to callback(@callback_object_class2).after(lifecycle).on(:update)
        end
        it "should have a meaningful description" do
          matcher = callback(@callback_object_class).after(lifecycle).on(:update)
          expect(matcher.description).to eq("callback Callback after #{lifecycle} on update")
        end
      end

      context "with conditions" do
        it "should match the if condition" do
          expect(@model).to callback(:dance!).after(lifecycle).if(:evaluates_to_false!)
        end
        it "should match the unless condition" do
          expect(@model).to callback(:shake!).after(lifecycle).unless(:evaluates_to_true!)
        end
        it "should not find callbacks not matching the conditions" do
          expect(@model).not_to callback(:giggle!).after(lifecycle).unless(:evaluates_to_false!)
        end
        it "should not find callbacks that are not there entirely" do
          expect(@model).not_to callback(:scream!).after(lifecycle).unless(:evaluates_to_false!)
        end
        it "should have a meaningful description" do
          matcher = callback(:dance!).after(lifecycle).unless(:evaluates_to_false!)
          expect(matcher.description).to eq("callback dance! after #{lifecycle} unless evaluates_to_false! evaluates to false")
        end

        it "should match the if condition" do
          expect(@model).to callback(@callback_object_class).after(lifecycle).if(:evaluates_to_false!)
        end
        it "should match the unless condition" do
          expect(@model).to callback(@callback_object_class).after(lifecycle).unless(:evaluates_to_true!)
        end
        it "should not find callbacks not matching the conditions" do
          expect(@model).not_to callback(@callback_object_class).after(lifecycle).unless(:evaluates_to_false!)
        end
        it "should not find callbacks that are not there entirely" do
          expect(@model).not_to callback(@callback_object_not_found_class).after(lifecycle).unless(:evaluates_to_false!)
        end
        it "should have a meaningful description" do
          matcher = callback(@callback_object_class).after(lifecycle).unless(:evaluates_to_false!)
          expect(matcher.description).to eq("callback Callback after #{lifecycle} unless evaluates_to_false! evaluates to false")
        end
      end

      context "with conditions and additional lifecycles" do
        it "should find the callback before the fact on create" do
          expect(@model).to callback(:dress!).after(lifecycle).on(:create)
        end
        it "should find the callback after the fact on update with the unless condition" do
          expect(@model).to callback(:shriek!).after(lifecycle).on(:update).unless(:evaluates_to_true!)
        end
        it "should find the callback after the fact on save with the if condition" do
          expect(@model).to callback(:pucker!).after(lifecycle).on(:destroy).if(:evaluates_to_false!)
        end
        it "should not find a callback for pucker! after the fact on save with the wrong condition" do
          expect(@model).not_to callback(:pucker!).after(lifecycle).on(:destroy).unless(:evaluates_to_false!)
        end
        it "should have a meaningful description" do
          matcher = callback(:dance!).after(lifecycle).on(:save).unless(:evaluates_to_false!)
          expect(matcher.description).to eq("callback dance! after #{lifecycle} on save unless evaluates_to_false! evaluates to false")
        end

        it "should find the callback before the fact on create" do
          expect(@model).to callback(@callback_object_class).after(lifecycle).on(:create)
        end
        it "should find the callback after the fact on update with the unless condition" do
          expect(@model).to callback(@callback_object_class).after(lifecycle).on(:update).unless(:evaluates_to_true!)
        end
        it "should find the callback after the fact on save with the if condition" do
          expect(@model).to callback(@callback_object_class2).after(lifecycle).on(:destroy).if(:evaluates_to_false!)
        end
        it "should not find a callback for Callback after the fact on save with the wrong condition" do
          expect(@model).not_to callback(@callback_object_class).after(lifecycle).on(:destroy).unless(:evaluates_to_false!)
        end
        it "should have a meaningful description" do
          matcher = callback(@callback_object_class).after(lifecycle).on(:destroy).unless(:evaluates_to_false!)
          expect(matcher.description).to eq("callback Callback after #{lifecycle} on destroy unless evaluates_to_false! evaluates to false")
        end
      end
    end
  end

  [:initialize, :find, :touch].each do |lifecycle|
    context "on #{lifecycle}" do
      before do

        @callback_object_class = define_model(:callback) do
          define_method("after_#{lifecycle}"){}
        end
        @callback_object_class2 = define_model(:callback2) do
          define_method("after_#{lifecycle}"){}
        end

        callback_object = @callback_object_class.new
        callback_object2 = @callback_object_class2.new

        @callback_object_not_found_class = define_model(:callback_not_found) do
          define_method("after_#{lifecycle}"){}
        end

        @model = define_model(:example, :attr  => :string,
                                        :other => :integer) do
          send(:"after_#{lifecycle}", :dance!, :if => :evaluates_to_false!)
          send(:"after_#{lifecycle}", :shake!, :unless => :evaluates_to_true!)
          send(:"after_#{lifecycle}", callback_object, :if => :evaluates_to_false!)
          send(:"after_#{lifecycle}", callback_object2, :unless => :evaluates_to_true!)
          define_method(:shake!){}
          define_method(:dance!){}

          define_method :evaluates_to_false! do
            false
          end

          define_method :evaluates_to_true! do
            true
          end

        end.new
      end

      context "as a simple callback test" do
        it "should not find a callback before the fact" do
          expect(@model).not_to callback(:dance!).before(lifecycle)
        end
        it "should find the callback after the fact" do
          expect(@model).to callback(:shake!).after(lifecycle)
        end
        it "should not find a callback around the fact" do
          expect(@model).not_to callback(:giggle!).around(lifecycle)
        end
        it "should not find callbacks that are not there" do
          expect(@model).not_to callback(:scream!).around(lifecycle)
        end
        it "should have a meaningful description" do
          matcher = callback(:dance!).before(lifecycle)
          expect(matcher.description).to eq("callback dance! before #{lifecycle}")
        end

        it "should not find a callback before the fact" do
          expect(@model).not_to callback(@callback_object_class).before(lifecycle)
        end
        it "should find the callback after the fact" do
          expect(@model).to callback(@callback_object_class).after(lifecycle)
        end
        it "should not find a callback around the fact" do
          expect(@model).not_to callback(@callback_object_class).around(lifecycle)
        end
        it "should not find callbacks that are not there" do
          expect(@model).not_to callback(@callback_object_not_found_class).around(lifecycle)
        end
        it "should have a meaningful description" do
          matcher = callback(@callback_object_class).before(lifecycle)
          expect(matcher.description).to eq("callback Callback before #{lifecycle}")
        end
      end

      context "with conditions" do
        it "should match the if condition" do
          expect(@model).to callback(:dance!).after(lifecycle).if(:evaluates_to_false!)
        end
        it "should match the unless condition" do
          expect(@model).to callback(:shake!).after(lifecycle).unless(:evaluates_to_true!)
        end
        it "should not find callbacks not matching the conditions" do
          expect(@model).not_to callback(:giggle!).around(lifecycle).unless(:evaluates_to_false!)
        end
        it "should not find callbacks that are not there entirely" do
          expect(@model).not_to callback(:scream!).before(lifecycle).unless(:evaluates_to_false!)
        end
        it "should have a meaningful description" do
          matcher = callback(:dance!).after(lifecycle).unless(:evaluates_to_false!)
          expect(matcher.description).to eq("callback dance! after #{lifecycle} unless evaluates_to_false! evaluates to false")
        end
        it "should match the if condition" do
          expect(@model).to callback(@callback_object_class).after(lifecycle).if(:evaluates_to_false!)
        end
        it "should match the unless condition" do
          expect(@model).to callback(@callback_object_class2).after(lifecycle).unless(:evaluates_to_true!)
        end
        it "should not find callbacks not matching the conditions" do
          expect(@model).not_to callback(@callback_object_class).around(lifecycle).unless(:evaluates_to_false!)
        end
        it "should not find callbacks that are not there entirely" do
          expect(@model).not_to callback(@callback_object_not_found_class).before(lifecycle).unless(:evaluates_to_false!)
        end
        it "should have a meaningful description" do
          matcher = callback(@callback_object_class).after(lifecycle).unless(:evaluates_to_false!)
          expect(matcher.description).to eq("callback Callback after #{lifecycle} unless evaluates_to_false! evaluates to false")
        end
      end

    end
  end
end
