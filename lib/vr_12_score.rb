require 'csv'

# @author Kevin Spevak
class Vr12Score
  QUESTION_LABELS = [:gh1, :pf02, :pf04, :vrp2, :vrp3, :vre2, :vre3, :bp2, :mh3, :vt2, :mh4, :sf2]

  # @return [String] The directory of the csv files containing the weights used to score the vr-12 survey.
  attr_accessor :weights_dir

  # @return [String] The name of the file containing weights for calculating the physical component
  #   score for a vr-12 survey administered by phone. Defaults to "pcs_phone.csv"
  attr_accessor :pcs_phone_file

  # @return [String] The name of the file containing weights for calculating the mental component
  #   score for a vr-12 survey administered by phone. Defaults to "mcs_phone.csv"
  attr_accessor :mcs_phone_file

  # @return [String] The name of the file containing weights for calculating the physical component
  #   score for a mail-out vr-12 survey. Defaults to "pcs_mail.csv"
  attr_accessor :pcs_mail_file

  # @return [String] The name of the file containing weights for calculating the mental component
  #   score for a mail-out vr-12 survey. Defaults to "mcs_mail.csv"
  attr_accessor :mcs_mail_file

  # @param weights_dir [String] ("weights") The name of the file containing weights for calculating
  #   the mental component score for a mail-out vr-12 survey.
  def initialize(weights_dir="weights")
    @weights_dir    = weights_dir
    @pcs_phone_file = "pcs_phone.csv"
    @mcs_phone_file = "mcs_phone.csv"
    @pcs_mail_file  = "pcs_mail.csv"
    @mcs_mail_file  = "mcs_mail.csv"
  end

  # Calculates the score for a response to the vr-12 survey
  # @param survey [Hash] The survey response data
  # @option survey [String] :type The method that was used to administer this survey. "phone" or "mail"
  # @return [Hash{Symbol => Number}] The physical component score and mental component score.
  def score(survey)
    if !survey || !survey.is_a?(Hash)
      raise ArgumentError.new("requires a hash of survey data")
    end
    if (QUESTION_LABELS - survey.keys).length > 0
      raise ArgumentError.new("Survey data missing keys for questions #{QUESTION_LABELS - survey.keys}")
    end
    non_numeric_labels = QUESTION_LABELS.select {|q| !(survey[q].nil? || survey[q].is_a?(Numeric))}
    if non_numeric_labels.length > 0
      raise ArgumentError.new("Values for questions #{non_numeric_labels} must be numeric or nil.")
    end
    if survey[:type] == "phone"
      pcs_data = pcs_phone_data
      mcs_data = mcs_phone_data
    elsif survey[:type] == "mail"
      pcs_data = pcs_mail_data
      mcs_data = mcs_mail_data
    else
      raise ArgumentError.new('Survey data must include a type that is either "phone" or "mail"')
    end

    # Convert answers to 0-100 scale values
    survey[:gh1] = case survey[:gh1]
                   when nil then nil
                   when 1 then 100
                   when 2 then 85
                   when 3 then 60
                   when 4 then 35
                   when 5 then 0
                   else raise ArgumentError.new("Value for :gh1 must be an integer from 1 to 5")
    end
    blank_questions = QUESTION_LABELS.select {|q| survey[q].nil?}
    ([:pf02, :pf04] - blank_questions).each do |q|
      raise ArgumentError.new("Value for #{q} must be an integer from 1 to 3") unless [1, 2, 3].include? survey[q]
      survey[q] = (survey[q] - 1) * 50
    end
    ([:vrp2, :vrp3, :vre2, :vre3, :bp2, :sf2] - blank_questions).each do |q|
      raise ArgumentError.new("Value for #{q} must be an integer from 1 to 5") unless (1..5).to_a.include? survey[q]
      survey[q] = (5 - survey[q]) * 25
    end
    survey[:sf5] = 100 - survey[:sf5] if survey[:sf5]
    ([:mh3, :vt2, :mh4] - blank_questions).each do |q|
      raise ArgumentError.new("Value for #{q} must be an integer from 1 to 6") unless (1..6).to_a.include? survey[q]
      survey[q] = (6 - survey[q]) * 20
    end
    survey[:mh4] = 100 - survey[:mh4] if survey[:mh4]

    # Find key to look up question weights based on blank questions
    key = 0
    blank_questions.each {|q| key |= 1 << QUESTION_LABELS.reverse.index(q)}

    pcs_row = pcs_data[:key].index(key)
    mcs_row = mcs_data[:key].index(key)
    pcs_weights = pcs_data[pcs_row]
    mcs_weights = mcs_data[mcs_row]

    # Calculate score by taking the weighted sum of the question responses given the appropriate weights,
    # then adding the appropriate constant term, based on which questions were answered.
    # Convert survey answers to integers to handle nil values (will not affect the weighted sum)
    # Add 'x' to end of question labels to look up weights to match the headers of the weight files.
    return {
      pcs: QUESTION_LABELS.map {|q| survey[q].to_i * pcs_weights[weight_name(q)]}.reduce(&:+) + pcs_weights[:cons],
      mcs: QUESTION_LABELS.map {|q| survey[q].to_i * mcs_weights[weight_name(q)]}.reduce(&:+) + mcs_weights[:cons]
    }
  end

  private

  # Convert question label to name of corresponding column in weights file
  def weight_name(question_label)
    (question_label.to_s.sub(/^vr/, "r") + "x").to_sym
  end

  def pcs_phone_data
    @pcs_phone_data ||= CSV.table(File.join(@weights_dir, @pcs_phone_file))
  end

  def mcs_phone_data
    @mcs_phone_data ||= CSV.table(File.join(@weights_dir, @mcs_phone_file))
  end

  def pcs_mail_data
    @pcs_mail_data ||= CSV.table(File.join(@weights_dir, @pcs_mail_file))
  end

  def mcs_mail_data
    @mcs_mail_data ||= CSV.table(File.join(@weights_dir, @mcs_mail_file))
  end
end
