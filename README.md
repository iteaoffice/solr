# SoloDB SOLR

Dedicated SOLR docker container for SOLR search engines, based on SOLR 10

## Search relevance (November 2026)

The accompanying ITEA application uses `Application\Search\SearchQuery` in all 35
text-query paths across 26 search services. Each service owns its explicit field
weights; the shared Jield package remains unchanged. Queries use local eDisMax
parameters so programmatic queries and facet filters still use the standard parser.
The existing `/select` handler needs no global parser change.

### Audit and changes

- The previous builder wrapped every unquoted word in `*word*`, including numeric
  and date fields. Leading wildcards bypass normal text analysis and their scores
  do not provide the usual term-frequency and length relevance. Search also mixed
  raw case-sensitive strings, analyzed fields and sort fields, with 50–100x boosts.
- Project queries included `project_sort` twice. The organisation VAT boost named
  a field that was not searched. Dedicated, explicitly weighted copies now remove
  both problems. Invoice dates and amounts are copied to analyzed text fields;
  numeric/date source fields retain their Point types and DocValues. Invoice date
  components are tokenized numerically so the date part also matches a timestamp.
- `*_relevance` uses StandardTokenizer, HTML stripping, lowercasing and ASCII
  folding at both index and query time. Query-time SynonymGraph supports curated
  multi-word synonyms. BM25 uses k1=1.2 and b=0.75 with positions and norms retained.
  The neutral analyzer avoids applying English stemming to multilingual names,
  project acronyms and text. It does not discard common words from names or phrases.
- `*_exact` uses KeywordTokenizer with lowercase and ASCII folding for whole-value
  identity matches. `*_prefix` uses index-time EdgeNGram (2–30 characters, original
  tokens preserved), and normal tokens at query time. Prefix recall has a lower
  weight; quoted phrases omit prefix fields. Arbitrary infix matching is no longer
  implicit. For example, `atl` finds Atlas, while `tlas` does not.
- eDisMax combines fields using tie=0.05, `sow=false`, and `mm=2<75%`: one/two-term
  queries require all terms; longer queries require 75%, rounded down. Exact phrase
  matches receive additional `pf` and bigram `pf2` boosts. User-entered field names,
  operators and local parameters remain literal; double quotes group phrases.
- Project weights: number token 10 / exact 30, name token 8 / exact 24, title token
  5 / exact 15, summary and challenge 2, description 1, identity prefixes 1. Phrase
  boosts are twice each selected token weight, with half that weight for bigrams.
  Other entities use comparable identity/title > metadata > body priorities.
- Public project queries previously discarded score sorting in favour of call or
  award year. Text queries now keep score sorting. Public news/magazine search and
  default idea-tool search also use relevance. Automatic score sorts have an ID
  tie-breaker for stable pagination.
- Scalar `text_gen_sort` fields now use English JDK collation at primary strength,
  ignoring case and accents. Copies into sort fields are limited to 1024 characters.
  Truly multivalued relation sort fields retain `SortableTextField` as
  `text_gen_sort_multi`: Solr 10 CollationField cannot sort multiple values. Their
  raw-value ordering is retained. These fields are no longer searched for relevance.
- Boolean types explicitly enable DocValues, fixing boolean sorting in Solr 10.
  Exact facet labels remain StrField/Point values with their existing capitalization;
  search normalization does not change stored labels or facet filtering semantics.
- Large string body/display fields are stored without a single keyword index term
  or DocValues. Search copies supply full-text indexing. Email bodies no longer
  need the old 32 KB truncation. This also avoids the Lucene oversized-term limit
  on long descriptions, summaries, HTML and message text.
- Legacy ASCII field query analyzers now fold accents as their index analyzers do.
  Bundled demonstration synonyms (e.g. MB/megabyte and television/TV) were removed;
  `synonyms.txt` is reserved for reviewed domain terms.
- Document/schema gaps are explicit: action `is_checked`, registration
  `contact_funder_id`, tender website + website_sort, and solution contact email +
  contact_sort. The obsolete calendar `internal` sort falls back to the date order.
  Incorrect duplicated lastname copy rules in the contact schema now populate the
  gender fields as intended.

### Validation

From the ITEA application checkout, with Composer dependencies, Python 3, Docker
and the local `solr:10` image available:

```shell
php vendor/bin/phpunit module/application/test/Search module/project/test/Search --no-coverage
python3 bin/check_search_relevance.py --solr-root ../solr/solr --image solr:10
```

The Python command checks PHP query fields, document mappings, sort/facet fields
and every XML file, then starts a fresh network-isolated Solr container. It loads
all cores, exercises every query profile, sort and facet, and checks synthetic
ranking, case/accent score equality, exact identifiers, phrase precision, graph
synonyms, prefixes, full long text, public filters, email and collation. It only
copies configuration, never an existing index, and removes its container on exit.

These are regression fixtures, not a production relevance benchmark. Before
changing weights further, build a judged set of representative real queries and
expected documents, then compare top results/NDCG and latency. Prefix fields add
index space; measure that and query latency against a representative corpus.

### Deployment and reindexing

**A fresh full index is required.** Field analysis, cardinality, DocValues and
collation types have changed. Reloading XML over old index segments is insufficient.
The application queries now require the new copy fields to be populated.

1. Bring up a fresh Solr instance or empty replacement cores with these configs.
   Keep the old instance available during the rebuild. The exploitable-result
   directory is `project_exploitable_result`, but its existing core name remains
   `project_achievement_exploitable_result`.
2. Point the new application's CLI at the replacement cores, and rebuild all
   entities with `php vendor/bin/laminas search:update-index all`. Use a full run;
   a shallow update or sync of missing documents will not populate every copy.
3. Verify document counts, sample queries, stored display values and facet counts.
   Switch the web application and its Solr endpoint together after indexing.
4. Roll back by returning both application and Solr endpoint to the old versions.
   Do not mix old and new index segments under the changed sort field types.

The source XML changes and test runs do not deploy or reindex application data.

References: [eDisMax](https://solr.apache.org/guide/solr/latest/query-guide/edismax-query-parser.html),
[field types and BM25](https://solr.apache.org/guide/solr/10_0/indexing-guide/field-type-definitions-and-properties.html),
[analysis filters](https://solr.apache.org/guide/solr/latest/indexing-guide/filters.html),
[collation](https://solr.apache.org/guide/solr/latest/indexing-guide/language-analysis.html#unicode-collation).

## Bulk update cores

```bash
find ./ -name 'core.properties' -type f -exec sed -i 's/name=/name=itea_dev_/g' {} \;
```

## Create a dedicated server on Azure for a SOLR service

Follow these instructions to create a dedicated Debian VM to host an SOLR instance on Azure.

Pre-requirements are a VLAN with an own subnet for intranet services

### Create VLAN

Go to azure and create new Virtual network and create a dedicated subnet for the website services (App service and SOLR)
Create 10.254.0.0/16 as address space and create

- 10.254.0.0/24 as subnet for production. (Web)
- 10.254.1.0/24 as subnet for VM

### Create VM

Create a Debian based virtual machine (D2s v3) and use a public key pair. Connect the VM to the production subnet

Install SOLR 10 (stand-alone). Solr 10 requires Java 21.

```shell
sudo apt-get update && sudo apt-get upgrade
sudo apt-get install openjdk-21-jdk
wget https://www.apache.org/dyn/closer.lua/solr/solr/10.0.0/solr-10.0.0.tgz?action=download
mv solr-10.0.0.tgz?action=download solr-10.0.0.tgz
tar xzf solr-10.0.0.tgz
sudo bash solr-10.0.0/bin/install_solr_service.sh solr-10.0.0.tgz
```

Change /etc/default/solr.in.sh so Solr listens to 0.0.0.0

```shell
# Sets the network interface the Solr binds to. To prevent administrators from
# accidentally exposing Solr more widely than intended, this defaults to 127.0.0.1.
# Administrators should think carefully about their deployment environment and
# set this value as narrowly as required before going to production. In
# environments where security is not a concern, 0.0.0.0 can be used to allow
# Solr to accept connections on all network interfaces.
SOLR_HOST_BIND="0.0.0.0"
```

Create a private/public key pair and save this in GitHub for deployment. Do this for solr and azureuser

```shell
ssh-keygen
```

```shell
sudo apt-get install git
```

Install PHP 8.1 cli to have cli operations

```shell
sudo apt-get install gnupg2
sudo echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/sury-php.list
sudo wget -qO - https://packages.sury.org/php/apt.gpg | sudo apt-key add -
sudo apt-get update && sudo apt-get upgrade
sudo apt-get install redis-server php8.1-cli php8.1-common php8.1-intl php-redis php8.1-gd php-igbinary php8.1-mysql php8.1-mbstring php8.1-zip php8.1-xml php8.1-curl php8.1-opcache php8.1-readline php8.1-soap php8.1-bcmath php8.1-redis php8.1-gmp
```
