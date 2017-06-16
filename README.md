# vr_12_score

A gem for scoring the VR12 instrument.
http://www.bu.edu/sph/research/research-landing-page/vr-36-vr-12-and-vr-6d/

## Usage
This gem requires the use of proprietary data files containing weights created through the statistical analysis of survey responses. The data files are not included in this repository.  Contact the developers of the survey to request access to these files.
http://www.bu.edu/sph/research/research-landing-page/vr-36-vr-12-and-vr-6d/request-access/

The four data files contain weights for calculating the physical component score (pcs) and mental component score (mcs) of surveys that were administered by phone interview or mail-out written questionnaire.  It is recommended that you rename these files on your system to ```pcs_phone.csv```, ```mcs_phone.csv```, ```pcs_mail.csv``` and ```mcs_mail.csv``` so the gem can find them with no additional configuration.  To initialize a new scorer, pass the directory containing these data files.

```
require "vr_12_score"
scorer = Vr12Score.new("/path/to/data/files")
```

If the data files are named differently, you can override the default names

```
scorer.pcs_phone_file = "custom_file_name.csv"
```

To score a survey, create a hash containing the survey responses under the labels defined in Vr12Score::QUESTION_LABELS. The survey hash must also contain the value "phone" or "mail" under the key ```:type```

```
puts survey.keys # [:type, :gh1, :pf02, :pf04, :vrp2, :vrp3, :vre2, :vre3, :bp2, :mh3, :vt2, :mh4, :sf2]
scorer.score(survey)
```

## Testing

Tests developed using RSpec 3.4.  Run the test suite with ```rake``` or ```rake test```

The file ```spec/test_data.csv``` contains 250 survey results and their corresponding mcs and pcs values.  These test cases are a subset of the 2000 that were included with the original R implementation of the VR12 scoring algorithm, in the file ```VR12 Test Data for R.xls```.  The original test data set was reduced because this gem was designed to be freely distributed independent of the proprietary weight data files, and the original test data set contained enough information to algebraically solve for some of the weights (12 or more surveys that use the same set of 12 weights).  Each entry in the reduced test data setuses a different set of weights.
