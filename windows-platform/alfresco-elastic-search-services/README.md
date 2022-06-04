# Alfresco Elasticsearch Connector

See documentation at https://docs.alfresco.com/search-services/latest/

Once the environment is up and running you can visit one of the URLs below:

- Alfresco Digital Workspace http://localhost:8080/workspace
- Share http://localhost:8080/share
- Alfresco Admin console http://localhost:8080/alfresco/s/enterprise/admin
- Alfresco http://localhost:8080/alfresco
- Elasticsearch http://localhost:9200
- Kibana http://localhost:5601
- ActiveMQ Web Console http://localhost:8161/admin/

You can log in to Alfresco applications using username _admin_ and password _admin_.

Once the environment has started, if you want, you can run a full re-index:

```shell
java -jar alfresco-elasticsearch-reindexing-*-app.jar \
--alfresco.reindex.jobName=reindexByIds \
--alfresco.reindex.pagesize=100 \
--alfresco.reindex.batchSize=100  \
--alfresco.reindex.fromId=0 \
--alfresco.reindex.toId=10000 \
--alfresco.reindex.concurrentProcessors=2
```

Please refer to full documentation in order to know more about live indexing and reindexing.