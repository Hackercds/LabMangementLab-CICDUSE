/**
 * 预约流程前端自动化测试
 */
describe('实验室管理系统 - 预约功能', () => {
  beforeEach(() => {
    // 先登录
    cy.visit('/#/login')
    cy.get('input[placeholder="请输入学号/工号"]').type('admin')
    cy.get('input[placeholder="请输入密码"]').type('admin123')
    cy.get('.el-button').contains('登录').click()
    cy.url().should('include', '/admin/dashboard')
    cy.visit('/#/student/reservation')
  })

  it('应该加载实验室列表', () => {
    cy.get('select[placeholder="请选择实验室"]').should('exist')
    cy.intercept('GET', '/api/lab/list').as('getLabs')
    cy.wait('@getLabs').then((interception) => {
      expect(interception.response.statusCode).to.equal(200)
      expect(interception.response.body.code).to.equal(200)
    })
  })

  it('选择实验室和日期后应该加载繁忙时间段', () => {
    cy.intercept('GET', '/api/lab/list').as('getLabs')
    cy.wait('@getLabs')
    cy.get('select[placeholder="请选择实验室"]').select('1')
    cy.get('.el-date-editor input').click()
    cy.get('.el-date-picker').contains('今天').click()
    cy.intercept('GET', '/api/reservation/busy*').as('getBusy')
    cy.wait('@getBusy')
    // 应该显示日历网格
    cy.get('.calendar-grid').should('exist')
  })
})
