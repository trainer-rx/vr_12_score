require "rspec"
require "vr_12_score"
require "csv"

describe Vr12Score do
  describe "#score" do
    it "calculates the correct pcs and mcs values for the test surveys" do
      scorer = Vr12Score.new("lib/weights")
      test_surveys = CSV.table("spec/test_data.csv")
      test_surveys.each do |survey_data|
        survey = Vr12Score::QUESTION_LABELS.map {|q| [q, survey_data[q]]}.to_h
        survey[:type] = survey_data[:type].downcase

        begin
          results = scorer.score(survey)
        rescue Errno::ENOENT
          puts "Could not find weight files.  Before running these tests, make" +
               " sure you have copies of the weight files in lib/weights, and" +
               " run rspec from the gem's root directory."
          fail
        end

        # Check that results match test data down to 6 decimal places
        # (Based on precision of original R code)
        if survey_data[:pcs].nil?
          expect(results[:pcs]).to be_nil
        else
          expect(results[:pcs]).to_not be_nil
          expect(results[:pcs]).to be_within(0.1 ** 6).of(survey_data[:pcs])
        end
        if survey_data[:mcs].nil?
          expect(results[:mcs]).to be_nil
        else
          expect(results[:mcs]).to_not be_nil
          expect(results[:mcs]).to be_within(0.1 ** 6).of(survey_data[:mcs])
        end
      end
    end
  end
end
