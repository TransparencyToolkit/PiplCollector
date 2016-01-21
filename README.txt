This requests information from Pipl based on fields in datasets in a
directory. It requires piplrequester
(https://github.com/transparencytoolkit/piplrequest) to work.

To run-
1. gem install piplrequester piplcollector
2. require piplcollector
3. p = PiplCollector.new("input_data_dir_path", "output_data_dir_path", "output_append_data_dir_path", "profile_url", "_terms.json",
"api_key", "field mapping hash (see piplrequest for instructions)")
p.run("input_data_dir_path")
