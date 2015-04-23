# Introduction #

ADCPtools is a set of functions to process ADCP data. The current functions are developed for RDI data formats.

Some of the concepts used in these functions are explained in more detail in the following publication:

Vermeulen, B., Sassi, M.G. and Hoitink, A.J.F
_Improved flow velocity estimates from moving-boat ADCP measurements_
Water Resources Research [doi:10.1002/2013WR015152](http://dx.doi.org/10.1002/2013WR015152)

Please refer to this work when using the functions from adcptools.

# Description of main functions #

## Read functions ##

| **Function name** | **Description** |
|:------------------|:----------------|
| `readadcp.m` | Reads RDI binary format (r-files)|
| `readNMEA.m` | Reads ascii NMEA input files (n,d,h-riles)|
| `readNMEAADCP.m` | Reads NMEA input files and combines them with the output from `readadcp.m`, matching the data based on time-stamps RDIENS NMEA strings |
| `readTfiles.m` | Reads ascii transect files (t-files)|
| `readDeployment.m` | Reads a compete deployment (runs the functions above to read all data belonging to one depolyment) |

## Data processing functions ##
| **Function name** | **Description** |
|:------------------|:----------------|
| `mapADCP.m` | Returns the position in space (as x,y,z offsets with respect to the ADCP), for all depth cells, and for each of the beams, taking into account the tilting of the instrument |
| `depthADCP.m` | Returns the position in space (as x,y,z offsets with respect to the ADCP), for the bottom or surface detection, for each of the beams, taking into account the tilting of the instruments (uses output from bottom tracking feature) |
| `filterADCP.m` | Filters velocity data and transforms velocity data from integer to double precision format. Acts both on water velocity and on bottom tracking velocity data |
| `corADCP.m` | Performs any coordinate transformation between beam,instrument,ship and earth coordinate systems for velocity data (both water velocity and bottom tracking velocity) |
| `utmADCP.m` | Looks for available GPS positioning information and transforms WGS84 lat/long coordinates to UTM x,y coordinates |

## Repeat transect processing ##
| **Function name** | **Description** |
|:------------------|:----------------|
| `procTrans.m` | Function to process vessel mounted repeat transect ADCP data |