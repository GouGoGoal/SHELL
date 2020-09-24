## [aliyuncli](https://help.aliyun.com/document_detail/110244.html) 
解析常用命令使用方法并简化，并可以根据预设规则来监控并调整DNS解析

##### 获取当前域名中所有的解析的域名名称、生存时间、解析记录ID、记录值,状态
```
aliyun alidns DescribeDomainRecords --DomainName test.com --output cols=RR,TTL,RecordId,Status,Value rows=DomainRecords.Record[] --PageSize 500 [--KeyWord www --SearchMode EXACT 用来筛选关键字]
```
##### 更改特定RecordId A|CNAME 记录
```
aliyun alidns UpdateDomainRecord --RecordId 00000000000000000 --RR www --Type (A|CNAME) --Value (1.1.1.1|test.com)
```
##### 启用|停用 特定RecordId的解析
```
aliyun alidns SetDomainRecordStatus --RecordId 00000000000000000 --Status (Enable|Disable)
```
##### 添加一个A|CNAME记录
```
aliyun alidns AddDomainRecord --DomainName test.com --RR www --Type (A|CNAME) --Value (1.1.1.1|test.com) [--TTL 600 可选项，默认600]
```
##### 删除特定RecordId的解析
```
aliyun alidns DeleteDomainRecord --RecordId 00000000000000000 
```