wards: tmp/ward1.csv \
	   tmp/ward2.csv \
	   tmp/ward3.csv \
	   tmp/ward4.csv \
	   tmp/ward5.csv \
	   tmp/ward6.csv \
	   tmp/ward7.csv \
	   tmp/ward8.csv \
	   tmp/ward10.csv \
	   tmp/ward11.csv \
	   tmp/ward12.csv \
	   tmp/ward13.csv

clwards: tmp/cl-ward1.csv \
	   tmp/cl-ward2.csv \
	   tmp/cl-ward3.csv \
	   tmp/cl-ward4.csv \
	   tmp/cl-ward5.csv \
	   tmp/cl-ward6.csv \
	   tmp/cl-ward7.csv \
	   tmp/cl-ward8.csv \
	   tmp/cl-ward10.csv \
	   tmp/cl-ward11.csv \
	   tmp/cl-ward12.csv \
	   tmp/cl-ward13.csv

## insert the ward via json and reconvert to CSV, also convert PID to string so
## it isn't mistreated later on.
tmp/cl-ward%.csv: tmp/ward%.csv
	@csv2json tmp/ward$*.csv | ndjson-split | ndjson-map 'd.PID = "" + d.PID, d.ward = $*, d' | ndjson-reduce 'p.push(d), p' '[]' | json2csv > $@
	@echo " $* -> $@ "

## Combine everything with only the header from the first file.
tmp/all-wards.csv: clwards
	@echo " - Putting it in one CSV."
	@awk 'FNR==1 && NR!=1{next;}{print}' tmp/cl-ward*.csv > $@
	@echo " --> $@"

## Combine everything from a ward file with only the header from the first file.
tmp/ward%.csv: tmp/ward%.processed
	@echo " - Combining ward $* tables"
	@awk 'FNR==1 && NR!=1{next;}{print}' tmp/ward$*/* > $@
	@echo " --> $@"

## {{{ individual ward processing with page number definitions
tmp/ward1: in/amendmenttables.pdf
	@echo " - Extracting tables."
	@mkdir -p tmp/ward1/
	camelot -p 1-9 -f csv --output tmp/ward1/ward1 lattice in/amendmenttables.pdf
	@touch $@
	@echo " --> $@"

tmp/ward2: in/amendmenttables.pdf
	@echo " - Extracting tables."
	@mkdir -p tmp/ward2/
	camelot -p 10-13 -f csv --output tmp/ward2/ward2 lattice in/amendmenttables.pdf
	@touch $@
	@echo " --> $@"

tmp/ward3: in/amendmenttables.pdf
	@echo " - Extracting tables."
	@mkdir -p tmp/ward3/
	camelot -p 14-16 -f csv --output tmp/ward3/ward3 lattice in/amendmenttables.pdf
	@touch $@
	@echo " --> $@"

tmp/ward4: in/amendmenttables.pdf
	@echo " - Extracting tables."
	@mkdir -p tmp/ward4/
	camelot -p 17-28 -f csv --output tmp/ward4/ward4 lattice in/amendmenttables.pdf
	@touch $@
	@echo " --> $@"

tmp/ward5: in/amendmenttables.pdf
	@echo " - Extracting tables."
	@mkdir -p tmp/ward5/
	camelot -p 29-35 -f csv --output tmp/ward5/ward5 lattice in/amendmenttables.pdf
	@touch $@
	@echo " --> $@"

tmp/ward6: in/amendmenttables.pdf
	@echo " - Extracting tables."
	@mkdir -p tmp/ward6/
	camelot -p 36-37 -f csv --output tmp/ward6/ward6 lattice in/amendmenttables.pdf
	@touch $@
	@echo " --> $@"

tmp/ward7: in/amendmenttables.pdf
	@echo " - Extracting tables."
	@mkdir -p tmp/ward7/
	camelot -p 38-71 -f csv --output tmp/ward7/ward7 lattice in/amendmenttables.pdf
	@touch $@
	@echo " --> $@"

tmp/ward8: in/amendmenttables.pdf
	@echo " - Extracting tables."
	@mkdir -p tmp/ward8/
	camelot -p 72-87 -f csv --output tmp/ward8/ward8 lattice in/amendmenttables.pdf
	@touch $@
	@echo " --> $@"

tmp/ward10: in/amendmenttables.pdf
	@echo " - Extracting tables."
	@mkdir -p tmp/ward10/
	camelot -p 88-92  -f csv --output tmp/ward10/ward10 lattice in/amendmenttables.pdf
	@touch $@
	@echo " --> $@"

tmp/ward11: in/amendmenttables.pdf
	@echo " - Extracting tables."
	@mkdir -p tmp/ward11/
	camelot -p 93-107 -f csv --output tmp/ward11/ward11 lattice in/amendmenttables.pdf
	@touch $@
	@echo " --> $@"

tmp/ward12: in/amendmenttables.pdf
	@echo " - Extracting tables."
	@mkdir -p tmp/ward12/
	camelot -p 108-133 -f csv --output tmp/ward12/ward12 lattice in/amendmenttables.pdf
	@touch $@
	@echo " --> $@"

tmp/ward13: in/amendmenttables.pdf
	@echo " - Extracting tables."
	@mkdir -p tmp/ward13/
	camelot -p 134-149 -f csv --output tmp/ward13/ward13 lattice in/amendmenttables.pdf
	@touch $@
	@echo " --> $@"

## }}}

amendedparcels.csv: tmp/all-wards.csv
	@cp $^ $@
	@echo " --> CSV"

amendedparcels.geojson: tmp/map_amendments
	@ogr2ogr -f "GeoJSON" $@ $^
	@echo " --> GeoJSON"

amendedparcels.kml: tmp/db.sqlite
	@ogr2ogr -f "KML" $@ $^
	@echo " --> KML"
	zip $@.zip $@

map_amendments_shapefiles.zip:
	@zip -j -r $@ tmp/map_amendments/
	@echo " --> Zip"

define SHP_QUERY
	SELECT parcels.*, pids.recommend, pids.amended, pids.Address, pids.ward  \
		FROM parcels, pids \
	WHERE parcels.PID = pids.PID; 
endef

## Run the query to align datasets.
tmp/map_amendments/map_amendments.shp: tmp/db.sqlite
	@echo " - Filtering"
	@ogr2ogr -f "ESRI Shapefile" \
		$@   \
		$^   \
		-dialect sqlite \
		-nln map_amendments \
		-sql "$(SHP_QUERY)"
	@echo " --> Filtered Shapefile"

## Throw all the bigger datasets in a single Spatialite file for easy querying
tmp/db.sqlite: tmp/all-wards.csv tmp/mplsparcels
	@echo " - Combining datasets"
	@echo "PID","Address","recommend","amended","ward" > tmp/all-wards-sqlsrc.csv
	@awk 'NR!=1{print}' tmp/all-wards.csv >> tmp/all-wards-sqlsrc.csv
	@ogr2ogr -f "SQLITE" $@ tmp/mplsparcels -nln parcels -dsco spatialite=yes -nlt MULTIPOLYGON
	@ogr2ogr -update -append -f "SQLITE" $@ tmp/all-wards-sqlsrc.csv -nln pids
	@echo " --> db.sqlite"

## Filter all the hennepin county parcels to a smaller file that is just
## Minneapolis parcels.
tmp/mplsparcels:
	@echo " @   $@"
	@echo " - Decompressing biggie"
	@unzip in/hennepin_county_parcels.zip -d tmp/hennepin_county_parcels
	@echo " - Processing to Shapefile"
	@ogr2ogr -f "ESRI Shapefile" \
		$@   \
		tmp/hennepin_county_parcels/   \
		-s_srs "EPSG:26915" \
		-t_srs "EPSG:4326" \
		-where "MUNIC_CD = '01'"
	@rm -rf tmp/hennepin_county_parcels
	@echo " --> SHP"

all: init \
	 virtualenv.exists \
	 wards \
	 clwards \
	 tmp/map_amendments \
	 amendedparcels.csv \
	 amendedparcels.geojson \
	 map_amendments_shapefiles.zip

clean:
	rm -rf tmp out env virtualenv.exists

virtualenv.exists: env
	echo "yes" > virtualenv.exists

env:
	@echo "Setting up environment: virtualenv & node"
	virtualenv --system-site-packages -p python2.7 env
	@echo "Installing packages"
	. env/bin/activate && pip install -r requirements.txt
	npm install
	@echo "Done."

init:
	@echo " Creating temp directories"
	@mkdir -p tmp
	@mkdir -p out

