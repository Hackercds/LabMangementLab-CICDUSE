/**
 * 登录流程前端自动化测试
 */
describe('实验室管理系统 - 登录功能', () => {
  beforeEach(() => {
    cy.visit('/#/login')
  })

  it('应该成功渲染登录页面', () => {
    cy.get('input[placeholder="请输入学号/工号"]').should('exist')
    cy.get('input[placeholder="请输入密码"]').should('exist')
    cy.contains('登录').should('exist')
  })

  it('空输入应该提示', () => {
    cy.get('.el-button').contains('登录').click()
    // 应该有提示
    cy.contains('请输入账号和密码')
  })

  it('错误密码应该提示错误', () => {
    cy.get('input[placeholder="请输入学号/工号"]').type('admin')
    cy.get('input[placeholder="请输入密码"]').type('wrongpassword')
    cy.get('.el-button').contains('登录').click()
    // 应该显示错误消息
    cy.get('.el-message--error').should('be.visible')
  })

  it('正确用户名密码应该登录成功并跳转', () => {
    cy.intercept('POST', '/api/auth/login').as('loginRequest')
    cy.get('input[placeholder="请输入学号/工号"]').type('admin')
    cy.get('input[placeholder="请输入密码"]').type('admin123')
    cy.get('.el-button').contains('登录').click()
    cy.wait('@loginRequest').then((interception) => {
      expect(interception.response.statusCode).to.equal(200)
      expect(interception.response.body.code).to.equal(200)
    })
    // 应该跳转到管理员仪表盘
    cy.url().should('include', '/admin/dashboard')
  })
})
