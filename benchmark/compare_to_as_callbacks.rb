require 'benchmark_driver'

Benchmark.driver do |x|
  x.prelude <<~RUBY
    require 'active_support/callbacks'
    require 'active_support/core_ext/object/blank'
    class Record
      include ActiveSupport::Callbacks
      define_callbacks :save

      def save
        run_callbacks :save do
          puts "- save"
        end
      end
    end

    class PersonRecord < Record
      set_callback :save, :before, :saving_message
      def saving_message
        puts "saving..."
      end

      set_callback :save, :after do |object|
        puts "saved"
      end
    end

    require 'tiny_hooks'

    class TinyRecord
      include TinyHooks

      def save
        puts '- save'
      end
    end

    class TinyPersonRecord < TinyRecord
      def saving_message
        puts 'saving...'
      end

      define_hook :before, :save, :saving_message

      define_hook :after, :save do
        puts 'saved'
      end
    end

    person = PersonRecord.new
    tiny_person = TinyPersonRecord.new
  RUBY

  x.report 'ActiveSupport Before', %( person.save )
  x.report 'TinyHooks Before', %( tiny_person.save )
end

Benchmark.driver do |x|
  x.prelude <<~RUBY
    require 'active_support/callbacks'
    require 'active_support/core_ext/object/blank'
    class Record
      include ActiveSupport::Callbacks
      define_callbacks :save

      def save
        run_callbacks :save do
          puts "- save"
        end
      end
    end

    class PersonRecord < Record
      set_callback :save, :around, lambda { |record, block|
        puts "saving..."
        block.call
        puts "saved"
        }
    end

    require 'tiny_hooks'

    class TinyRecord
      include TinyHooks

      def save
        puts '- save'
      end
    end

    class TinyPersonRecord < TinyRecord
      define_hook :around, :save do |original|
        puts "saving..."
        original.call
        puts "saved"
      end
    end

    person = PersonRecord.new
    tiny_person = TinyPersonRecord.new
  RUBY

  x.report 'ActiveSupport Around', %( person.save )
  x.report 'TinyHooks Around', %( tiny_person.save )
end

Benchmark.driver do |x|
  x.prelude <<~RUBY
    require 'active_support/callbacks'
    require 'active_support/core_ext/object/blank'

    class ASNoCallbackSet
      include ActiveSupport::Callbacks
      define_callbacks :save

      def save
        run_callbacks :save do
          puts "- save"
        end
      end
    end

    require 'tiny_hooks'

    class TinyNoCallbackSet
      include TinyHooks

      def save
        puts '- save'
      end
    end

    class Plain
      def save
        puts '- save'
      end
    end

    as_no_callback_set = ASNoCallbackSet.new
    tiny_no_callback_set = TinyNoCallbackSet.new
    plain = Plain.new
  RUBY

  x.report 'ActiveSupport no callback set', %( as_no_callback_set.save )
  x.report 'TinyHooks no callback set', %( tiny_no_callback_set.save )
  x.report 'Plain', %( plain.save )
end
