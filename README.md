# About this dataset

This is combined from 2018 [hennepin county parcel data][hennparcels], and
tables precent in the accidentally released #mpls2040 map amendments PDF. Data
was liberated from the PDF using `camelot-py`, and combined with assessor
records using `ogr2ogr`. For a description of county parcel columns, see that dataset. Map amendment columns are as follows:

 * `recommend` - Recommended land use / built form in the pre-council markup.
 * `amended` - Amended in released data
 * `address` - address according to released data.
 * `ward` - Minneapolis ward

  [hennparcels]: https://www.arcgis.com/home/item.html?id=7975aabf6e1e42998a40a4b085ffefdf

## Releases

Note, everything but the CSV format contains spatial data.

## Compiling it yourself

If the PDF is updated, you probably want to build it yourself. Check out
the files in `in/`, make any replacements (keep the same structure-- chop
off the maps and keep the tables, make sure the text is machine readable
like the first version).

You'll need python2.7, and `virtualenv`, and node/npm. Theoretically running
the following should configure a virtualenvironment with the python packages
and node packages necessary to build. The main one for PDF magic is
`camelot-py`, so if that breaks, welp...


Download the [county dataset][hennparcels] and put it here:

    in/hennepin_county_parcels.zip

Set up the environment with: 

    make init
    make env

Build the output zip with:

    make all

NB: Camelot will probably take ~10 minutes to process all the pages.
