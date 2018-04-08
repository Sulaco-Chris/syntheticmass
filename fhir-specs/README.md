SyntheticMass FHIR Server Specification
============================

This test suite defines a minimum set of requirements for a FHIR server to support SyntheticMass.  Synthetic Mass requires 
a FHIR server that can fulfill an analytics use case, capable of advanced FHIR search queries over
millions of patient records.  It also must be able to support queries from web clients (with JSON responses), 
as SyntheticMass provides a web-based visualization and all queries are issued directly from the client browser.

Functional requirements include:

* DSTU3
* Json
* Read and (advanced) search for the following resources:
    * Patient
    * Observation
    * Condition
    * Immunization
    * MedicationRequest
    * Procedure
    * Encounter
    * CarePlan
* Patients contain address information (and are searchable by address-city)
* Bundle paging and navigation
* Patient $everything operator

This does not test performance requirements.  See the python scripts in `fhir-benchmarks` for that type of testing.

All tests are written assuming the server contains a large set of (synthetic) patient data available for querying.
An empty or sparsely filled server will likely not pass these tests.

System Requirements:
* Ruby 2.4+

Installation
------------
```sh
   # install ruby, bundler
   bundle install
```

To run:
------------

```sh
bundle exec ruby app.rb FHIR_ENDPOINT_URI
```

By default, the tests attempt to locate a suitable Patient ID to use, a valid city to search against, and uses
common condition codes that are likely to appear in a realistic synthetic data set.  However, you can pass in 
your own as well with the `--patient`, `--city` and `--condition` flag.  More information is available with `--help`.
