/**
 * 耗材领用前端自动化测试
 */
describe('实验室管理系统 - 耗材领用', () => {
  beforeEach(() => {
    cy.visit('/#/login')
    cy.get('input[placeholder="请输入学号/工号"]').type('admin')
    cy.get('input[placeholder="请输入密码"]').type('admin123')
    cy.get('.el-button').contains('登录').click()
    cy.url().should('include', '/admin/dashboard')
    cy.visit('/#/admin/consumable')
  })

  it('应该加载耗材列表', () => {
    cy.intercept('GET', '/api/consumable/page*').as('getConsumables')
    cy.wait('@getConsumables').then((interception) => {
      expect(interception.response.statusCode).to.equal(200)
      expect(interception.response.body.code).to.equal(200)
    })
    cy.get('el-table').should('exist')
  })

  it('低库存耗材应该显示红色标签', () => {
    cy.intercept('GET', '/api/consumable/page*').as('getConsumables')
    cy.wait('@getConsumables')
    // 如果有低库存，应该显示红色标签
    cy.get('.el-tag.type-danger').should('exist')
  })
})
