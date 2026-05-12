with open('实验室管理系统综合性能测试.jmx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find E group: from ThreadGroup to closing hashTree before F group
e_tg = content.find('E-审批并发')
e_tg = content.rfind('<ThreadGroup', 0, e_tg)
f_tg = content.find('F-峰值读取')
before_f = content[:f_tg]
e_end = before_f.rfind('</hashTree>')

new_e = '''<ThreadGroup guiclass="ThreadGroupGui" testclass="ThreadGroup" testname="E-审批并发(50用户)" enabled="true">
        <intProp name="ThreadGroup.num_threads">50</intProp>
        <intProp name="ThreadGroup.ramp_time">2</intProp>
        <boolProp name="ThreadGroup.same_user_on_next_iteration">true</boolProp>
        <stringProp name="ThreadGroup.on_sample_error">continue</stringProp>
        <elementProp name="ThreadGroup.main_controller" elementType="LoopController" guiclass="LoopControlPanel" testclass="LoopController" testname="循环控制器">
          <stringProp name="LoopController.loops">1</stringProp>
          <boolProp name="LoopController.continue_forever">false</boolProp>
        </elementProp>
      </ThreadGroup>
      <hashTree>
        <HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="E01-管理员登录" enabled="true">
          <stringProp name="HTTPSampler.domain">${BASEURL}</stringProp>
          <stringProp name="HTTPSampler.port">${PORT}</stringProp>
          <stringProp name="HTTPSampler.protocol">http</stringProp>
          <stringProp name="HTTPSampler.path">/api/auth/login</stringProp>
          <boolProp name="HTTPSampler.auto_redirects">true</boolProp>
          <stringProp name="HTTPSampler.method">POST</stringProp>
          <boolProp name="HTTPSampler.use_keepalive">true</boolProp>
          <boolProp name="HTTPSampler.postBodyRaw">true</boolProp>
          <elementProp name="HTTPsampler.Arguments" elementType="Arguments">
            <collectionProp name="Arguments.arguments">
              <elementProp name="" elementType="HTTPArgument">
                <boolProp name="HTTPArgument.always_encode">false</boolProp>
                <stringProp name="Argument.value">{&quot;username&quot;:&quot;${ADMIN_USER}&quot;,&quot;password&quot;:&quot;${ADMIN_PASS}&quot;}</stringProp>
                <stringProp name="Argument.metadata">=</stringProp>
              </elementProp>
            </collectionProp>
          </elementProp>
          <stringProp name="HTTPSampler.implementation">HttpClient4</stringProp>
        </HTTPSamplerProxy>
        <hashTree>
          <HeaderManager guiclass="HeaderPanel" testclass="HeaderManager" testname="HTTP信息头管理器" enabled="true">
            <collectionProp name="HeaderManager.headers">
              <elementProp name="" elementType="Header">
                <stringProp name="Header.name">Content-Type</stringProp>
                <stringProp name="Header.value">application/json</stringProp>
              </elementProp>
              <elementProp name="" elementType="Header">
                <stringProp name="Header.name">Accept-Encoding</stringProp>
                <stringProp name="Header.value">gzip,deflate,br</stringProp>
              </elementProp>
            </collectionProp>
          </HeaderManager>
          <hashTree/>
          <JSONPostProcessor guiclass="JSONPostProcessorGui" testclass="JSONPostProcessor" testname="提取token" enabled="true">
            <stringProp name="JSONPostProcessor.referenceNames">approveToken</stringProp>
            <stringProp name="JSONPostProcessor.jsonPathExprs">$.data.token</stringProp>
            <stringProp name="JSONPostProcessor.match_numbers">1</stringProp>
            <stringProp name="JSONPostProcessor.defaultValues">NOT_FOUND</stringProp>
          </JSONPostProcessor>
          <hashTree/>
        </hashTree>
        <HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="E02-查询待审批预约" enabled="true">
          <stringProp name="HTTPSampler.domain">${BASEURL}</stringProp>
          <stringProp name="HTTPSampler.port">${PORT}</stringProp>
          <stringProp name="HTTPSampler.protocol">http</stringProp>
          <stringProp name="HTTPSampler.path">/api/reservation/list?current=1&amp;size=10&amp;status=PENDING</stringProp>
          <boolProp name="HTTPSampler.auto_redirects">true</boolProp>
          <stringProp name="HTTPSampler.method">GET</stringProp>
          <boolProp name="HTTPSampler.use_keepalive">true</boolProp>
          <stringProp name="HTTPSampler.implementation">HttpClient4</stringProp>
        </HTTPSamplerProxy>
        <hashTree>
          <HeaderManager guiclass="HeaderPanel" testclass="HeaderManager" testname="HTTP信息头管理器" enabled="true">
            <collectionProp name="HeaderManager.headers">
              <elementProp name="" elementType="Header">
                <stringProp name="Header.name">Authorization</stringProp>
                <stringProp name="Header.value">Bearer ${approveToken}</stringProp>
              </elementProp>
              <elementProp name="" elementType="Header">
                <stringProp name="Header.name">Accept-Encoding</stringProp>
                <stringProp name="Header.value">gzip,deflate,br</stringProp>
              </elementProp>
            </collectionProp>
          </HeaderManager>
          <hashTree/>
          <JSONPostProcessor guiclass="JSONPostProcessorGui" testclass="JSONPostProcessor" testname="提取reservationId" enabled="true">
            <stringProp name="JSONPostProcessor.referenceNames">resId</stringProp>
            <stringProp name="JSONPostProcessor.jsonPathExprs">$.data.records[0].id</stringProp>
            <stringProp name="JSONPostProcessor.match_numbers">1</stringProp>
            <stringProp name="JSONPostProcessor.defaultValues">NOT_FOUND</stringProp>
          </JSONPostProcessor>
          <hashTree/>
        </hashTree>
        <HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="E03-审批预约(FOR UPDATE竞态)" enabled="true">
          <stringProp name="HTTPSampler.domain">${BASEURL}</stringProp>
          <stringProp name="HTTPSampler.port">${PORT}</stringProp>
          <stringProp name="HTTPSampler.protocol">http</stringProp>
          <stringProp name="HTTPSampler.path">/api/reservation/${resId}/approve?status=APPROVED&amp;comment=并发审批测试-${__threadNum}</stringProp>
          <boolProp name="HTTPSampler.auto_redirects">true</boolProp>
          <stringProp name="HTTPSampler.method">PUT</stringProp>
          <boolProp name="HTTPSampler.use_keepalive">true</boolProp>
          <stringProp name="HTTPSampler.implementation">HttpClient4</stringProp>
        </HTTPSamplerProxy>
        <hashTree>
          <HeaderManager guiclass="HeaderPanel" testclass="HeaderManager" testname="HTTP信息头管理器" enabled="true">
            <collectionProp name="HeaderManager.headers">
              <elementProp name="" elementType="Header">
                <stringProp name="Header.name">Authorization</stringProp>
                <stringProp name="Header.value">Bearer ${approveToken}</stringProp>
              </elementProp>
              <elementProp name="" elementType="Header">
                <stringProp name="Header.name">Accept-Encoding</stringProp>
                <stringProp name="Header.value">gzip,deflate,br</stringProp>
              </elementProp>
            </collectionProp>
          </HeaderManager>
          <hashTree/>
          <DurationAssertion guiclass="DurationAssertionGui" testclass="DurationAssertion" testname="响应时间断言(<5000ms)" enabled="true">
            <stringProp name="DurationAssertion.duration">5000</stringProp>
          </DurationAssertion>
          <hashTree/>
        </hashTree>
      </hashTree>
'''

content = content[:e_tg] + new_e + content[e_end + len('</hashTree>'):]

with open('实验室管理系统综合性能测试.jmx', 'w', encoding='utf-8') as f:
    f.write(content)

# Validate
import xml.etree.ElementTree as ET
tree = ET.parse('实验室管理系统综合性能测试.jmx')
root = tree.getroot()
testplan = root.find('hashTree').find('hashTree')
children = list(testplan)
for i, c in enumerate(children):
    if c.tag in ('ThreadGroup','SetupThreadGroup','PostThreadGroup'):
        name = c.get('testname','')
        ht = list(children[i+1])
        samplers = [x for x in ht if x.tag == 'HTTPSamplerProxy']
        csv_count = sum(1 for x in ht if x.tag == 'CSVDataSet')
        has_admin = any('ADMIN_USER' in (e.text or '') for x in ht for e in x.iter() if e.text)
        print(f'{name}: {len(samplers)} samplers, {csv_count} CSV, admin={has_admin}')

issues = sum(1 for i,c in enumerate(children) if c.tag in ('ThreadGroup','SetupThreadGroup','PostThreadGroup')
    for j in range(len(list(children[i+1]))-1)
    if list(children[i+1])[j].tag=='hashTree' and list(children[i+1])[j+1].tag=='hashTree')
print(f'Issues: {issues}')
