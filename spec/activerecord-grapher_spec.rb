require 'active_record'
require 'activerecord-grapher'

RSpec.describe ActiveRecord::Grapher, ".build_graph" do
  context "with a :belongs_to association" do
    before do
      class Author < ActiveRecord::Base
      end

      class Book < ActiveRecord::Base
          belongs_to :author
      end
    end

    after do
      remove_constants(:Author, :Book)
    end

    it "adds the classes to the graph and connects them" do
      graph = ActiveRecord::Grapher.build_graph()

      expect(graph.has_edge?(Book, Author)).to eq true
    end
  end

  context "with a :has_one association" do
    context "with no :through" do
      before do
        class Account < ActiveRecord::Base
        end

        class Supplier < ActiveRecord::Base
            has_one :account
        end
      end

      after do
        remove_constants(:Account, :Supplier)
      end

      it "adds the classes to the graph and connects them" do
        graph = ActiveRecord::Grapher.build_graph()

        expect(graph.has_edge?(Account, Supplier)).to eq true
      end
    end

    context "with a :through" do
      before do
        class Supplier < ActiveRecord::Base
          has_one :account
					has_one :account_history, through: :account
				end

				class Account < ActiveRecord::Base
          belongs_to :supplier
          has_one :account_history
				end

				class AccountHistory < ActiveRecord::Base
          belongs_to :account
				end
      end

      after do
        remove_constants(:Supplier, :Account, :AccountHistory)
      end

      it "adds the classes to the graph and connects them" do
        graph = ActiveRecord::Grapher.build_graph()

        expect(graph.has_edge?(AccountHistory, Account)).to eq true
        expect(graph.has_edge?(Account, Supplier)).to eq true
      end
    end

    context "with an incorrectly configured :through" do
      before do
        class Supplier < ActiveRecord::Base
					has_one :account_history, through: :account
				end

				class Account < ActiveRecord::Base
				end

				class AccountHistory < ActiveRecord::Base
				end
      end

      after do
        remove_constants(:Supplier, :Account, :AccountHistory)
      end

      it "does not add the classes to the graph" do
        expect(Rails.logger).to receive(:warn).with("Tried and failed to parse a :has_one :through association from model Supplier. This can be due to a missing non-:through :has_one association on the model (Supplier).")

        graph = ActiveRecord::Grapher.build_graph()

        expect(graph.has_edge?(AccountHistory, Account)).to eq false
        expect(graph.has_edge?(Account, Supplier)).to eq false
      end
    end
  end

  context "with a :has_many association" do
    context "with no :through" do
      before do
        class Book < ActiveRecord::Base
        end

        class Author < ActiveRecord::Base
          has_many :books
        end
      end

      after do
        remove_constants(:Book, :Author)
      end

      it "adds the classes to the graph and connects them" do
        graph = ActiveRecord::Grapher.build_graph()

        expect(graph.has_edge?(Book, Author)).to eq true
      end
    end

    context "with a :through" do
      before do
				class Physician < ActiveRecord::Base
					has_many :appointments
					has_many :patients, through: :appointments
				end

				class Appointment < ActiveRecord::Base
					belongs_to :physician
					belongs_to :patient
				end

				class Patient < ActiveRecord::Base
					has_many :appointments
					has_many :physicians, through: :appointments
				end
      end

      after do
        remove_constants(:Physician, :Patient, :Appointment)
      end

      it "adds the classes to the graph and connects them" do
        graph = ActiveRecord::Grapher.build_graph()

        expect(graph.has_edge?(Appointment, Physician)).to eq true
        expect(graph.has_edge?(Appointment, Patient)).to eq true
      end
    end

    context "with an incorrectly configured :through" do
      before do
				class Physician < ActiveRecord::Base
					has_many :patients, through: :appointments
				end

				class Appointment < ActiveRecord::Base
				end

				class Patient < ActiveRecord::Base
				end
      end

      after do
        remove_constants(:Physician, :Patient, :Appointment)
      end

      it "does not add the classes to the graph" do
        expect(Rails.logger).to receive(:warn).with("Tried and failed to parse a :has_many :through association from model Physician. This can be due to a missing non-:through :has_many association on the model (Physician).")

        graph = ActiveRecord::Grapher.build_graph()

        expect(graph.has_edge?(Appointment, Physician)).to eq false
        expect(graph.has_edge?(Appointment, Patient)).to eq false
      end
    end
  end

  context "with a :has_and_belongs_to_many association" do
    before do
      class Assembly < ActiveRecord::Base
				has_and_belongs_to_many :parts
			end

			class Part < ActiveRecord::Base
				has_and_belongs_to_many :assemblies
			end
    end

    after do
      remove_constants(:Assembly, :Part)
    end

    it "adds the join models to the graph and connects them" do
      graph = ActiveRecord::Grapher.build_graph()

      join_models = Set.new([Assembly.const_get(:HABTM_Parts), Part.const_get(:HABTM_Assemblies)])
      expect(graph.has_edge?(join_models, Assembly)).to eq true
      expect(graph.has_edge?(join_models, Part)).to eq true
    end
  end
end
