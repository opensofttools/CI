# CI搭建

***CI: 持续集成（英语：Continuous integration，缩写CI）是一种软件工程流程，是将所有软件工程师对于软件的工作副本持续集成到共用主线（mainline）的一种举措。该名称最早由[1]葛来迪·布区（Grady Booch）在他的布区方法[2]中提出，不过他并不支持在一天中进行数次集成。之后该举措成为极限编程（extreme programming）的一部分时，其中建议每天应集成超过一次，甚至达到数十次。[3]在测试驱动开发（TDD）的作法中，通常还会搭配自动单元测试。持续集成的提出主要是为解决软件进行系统集成时面临的各项问题，极限编程称这些问题为集成地狱（integration hell）。***  

**系统整体采用openstack的CI方式，组要组件有openldap，gerrit，gitlab，zuul，jenkins，gearman.**  
### 基本组件介绍:

* openldap：认证
* gerrit: 代码审核
* gitlab：代码仓库
* zuul：网关
* jenkins：代码测试
* gearman：？

### 系统部署规划:

* 域名
    * jumpserver.xyz
* 端口  
    - jenkins: 8080
    - gerrit: 28080、29418
    - gitlab: 18080
    - zuul: 80
    - gearman: 4730
    - openldap: 389、636
    - ldapadmin: 38080、38443
    - openvpn: 1194   

### install

##### alpine install openldap
