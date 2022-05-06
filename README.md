# solr
Dedicated SOLR docker container for ITEA search engines

Based on SOLR latest

Code to bulk update cores
```bash
find ./ -name 'core.properties' -type f -exec sed -i 's/name=/name=itea_dev_/g' {} \;
```