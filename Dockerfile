FROM solr:latest
LABEL maintainer="info@jield.nl"
LABEL org.opencontainers.image.source="https://github.com/jield-webdev/solodb-solr/solr"

ENV SOLR_OPTS="-XX:-UseLargePages"

ADD --chown=solr:solr solr/calendar_calendar /var/solr/data/calendar_calendar
ADD --chown=solr:solr solr/contact_contact /var/solr/data/contact_contact
ADD --chown=solr:solr solr/contact_profile /var/solr/data/contact_profile
ADD --chown=solr:solr solr/event_registration /var/solr/data/event_registration
ADD --chown=solr:solr solr/general_country /var/solr/data/general_country
ADD --chown=solr:solr solr/invoice_invoice /var/solr/data/invoice_invoice
ADD --chown=solr:solr solr/news_blog /var/solr/data/news_blog
ADD --chown=solr:solr solr/news_news /var/solr/data/news_news
ADD --chown=solr:solr solr/organisation_advisory_board_solution /var/solr/data/organisation_advisory_board_solution
ADD --chown=solr:solr solr/organisation_advisory_board_city /var/solr/data/organisation_advisory_board_city
ADD --chown=solr:solr solr/organisation_advisory_board_city_tender /var/solr/data/organisation_advisory_board_city_tender
ADD --chown=solr:solr solr/organisation_organisation /var/solr/data/organisation_organisation
ADD --chown=solr:solr solr/press_press /var/solr/data/press_press
ADD --chown=solr:solr solr/project_achievement /var/solr/data/project_achievement
ADD --chown=solr:solr solr/project_action /var/solr/data/project_action
ADD --chown=solr:solr solr/project_exploitable_result /var/solr/data/project_exploitable_result
ADD --chown=solr:solr solr/project_idea /var/solr/data/project_idea
ADD --chown=solr:solr solr/project_project /var/solr/data/project_project
ADD --chown=solr:solr solr/project_result /var/solr/data/project_result
ADD --chown=solr:solr solr/project_roadmap /var/solr/data/project_roadmap
ADD --chown=solr:solr solr/project_version /var/solr/data/project_version
ADD --chown=solr:solr solr/project_version_document /var/solr/data/project_version_document
ADD --chown=solr:solr solr/project_workpackage_document /var/solr/data/project_workpackage_document
ADD --chown=solr:solr solr/publication_publication /var/solr/data/publication_publication