# 🚀 WARP AI DEVELOPMENT PROMPTS - MCP INTEGRATION
*Comprehensive Vietnamese Prompts for Development Scenarios*

## 📋 **GIỚI THIỆU**

Bộ prompts này được thiết kế để tối ưu hóa việc sử dụng **Warp AI** và **Augment AI** trong các tình huống development thực tế, với **MCP (Model Context Protocol)** integration để kết nối hiệu quả với external systems.

### **MCP Integration Overview**
- **MCP Servers**: Expose data và tools (codebase, git, development tools)
- **MCP Clients**: AI applications connect to servers
- **Standardized Protocol**: Giống USB-C cho AI applications

---

## 🔧 **MCP SETUP REQUIREMENTS**

### **Required MCP Servers**
```yaml
# Codebase Server
- name: "codebase-server"
  type: "file-system"
  access: ["read", "write", "analyze"]
  
# Git Server  
- name: "git-server"
  type: "version-control"
  access: ["history", "branches", "commits"]
  
# Development Tools Server
- name: "dev-tools-server"
  type: "tools"
  access: ["linters", "formatters", "test-runners"]
  
# Documentation Server
- name: "docs-server"
  type: "knowledge-base"
  access: ["api-docs", "internal-docs", "standards"]
```

### **Connection Verification**
```bash
# Verify MCP connections before starting
mcp-client list-servers
mcp-client test-connection codebase-server
mcp-client test-connection git-server
```

---

## 🎯 **SCENARIO 1: PHÂN TÍCH PROJECT**

### **MCP Requirements**
- ✅ Codebase Server (full access)
- ✅ Git Server (history access)
- ✅ Documentation Server (read access)

### **Prompt Template**
```
🔍 **PHÂN TÍCH TOÀN DIỆN PROJECT**

**MCP Integration Setup:**
1. Kết nối với codebase-server để access project files
2. Connect git-server để analyze commit history và patterns
3. Access docs-server để understand existing documentation

**Nhiệm vụ chính:**
Thực hiện phân tích comprehensive project hiện tại với focus vào:

**PHASE 1: ARCHITECTURE ANALYSIS**
- Sử dụng MCP codebase-server để scan toàn bộ project structure
- Identify main components, modules, và dependencies
- Analyze architectural patterns được sử dụng (MVC, MVVM, Clean Architecture, etc.)
- Map out data flow và component relationships

**PHASE 2: CODE QUALITY ASSESSMENT**
- Connect dev-tools-server để run code quality analysis
- Identify technical debt areas
- Analyze naming conventions compliance (theo existing rules)
- Assess test coverage và documentation quality

**PHASE 3: HISTORICAL ANALYSIS**
- Sử dụng git-server để analyze commit patterns
- Identify frequently changed files (potential hotspots)
- Understand development velocity và team patterns
- Extract lessons learned từ commit messages

**PHASE 4: DEPENDENCY ANALYSIS**
- Map external dependencies và their versions
- Identify potential security vulnerabilities
- Analyze dependency update patterns
- Assess impact of major dependencies

**Expected Output:**
1. **Architecture Diagram**: Visual representation của system
2. **Quality Report**: Detailed assessment với actionable recommendations
3. **Risk Assessment**: Potential issues và mitigation strategies
4. **Improvement Roadmap**: Prioritized list của enhancements

**Quality Gates:**
- [ ] All major components identified và documented
- [ ] Architecture patterns clearly mapped
- [ ] Quality metrics established với baselines
- [ ] Risk factors identified với mitigation plans

**MCP Validation:**
- Verify codebase-server provided complete file access
- Confirm git-server delivered comprehensive history
- Ensure docs-server contributed to understanding
```

---

## 🆕 **SCENARIO 2: THÊM TÍNH NĂNG MỚI**

### **MCP Requirements**
- ✅ Codebase Server (read/write access)
- ✅ Git Server (pattern analysis)
- ✅ Dev Tools Server (code generation)

### **Prompt Template**
```
⚡ **THÊM TÍNH NĂNG MỚI THEO PATTERN HIỆN TẠI**

**MCP Integration Setup:**
1. Connect codebase-server để analyze existing patterns
2. Use git-server để understand feature development history
3. Access dev-tools-server để ensure code quality

**Nhiệm vụ chính:**
Implement tính năng mới [TÊN_TÍNH_NĂNG] following established project patterns.

**PHASE 1: PATTERN RECOGNITION**
- Sử dụng MCP codebase-server để identify similar existing features
- Analyze code structure, naming conventions, và architectural patterns
- Extract reusable templates và boilerplate code
- Document pattern compliance requirements

**PHASE 2: DESIGN ALIGNMENT**
- Connect git-server để study how similar features were implemented
- Identify best practices từ successful feature additions
- Plan integration points với existing codebase
- Design API contracts consistent với current patterns

**PHASE 3: IMPLEMENTATION**
- Generate code templates using identified patterns
- Implement core functionality following established conventions
- Ensure proper error handling và logging patterns
- Add comprehensive unit tests matching existing test patterns

**PHASE 4: INTEGRATION**
- Connect new feature với existing dependency injection
- Update routing/navigation patterns appropriately
- Ensure proper data flow integration
- Add feature flags for gradual rollout

**Expected Output:**
1. **Feature Implementation**: Complete, tested code
2. **Integration Guide**: How feature connects với existing system
3. **Test Suite**: Comprehensive test coverage
4. **Documentation**: API docs và usage examples

**Quality Gates:**
- [ ] Code follows established naming conventions
- [ ] Architecture patterns properly implemented
- [ ] Test coverage meets project standards (>90%)
- [ ] Integration points properly handled

**MCP Validation:**
- Confirm pattern analysis was comprehensive
- Verify code generation follows project standards
- Ensure integration testing completed successfully
```

---

## 🐛 **SCENARIO 3: FIX BUG**

### **MCP Requirements**
- ✅ Codebase Server (full access)
- ✅ Git Server (blame/history analysis)
- ✅ Dev Tools Server (debugging tools)

### **Prompt Template**
```
🔧 **SYSTEMATIC BUG FIXING**

**MCP Integration Setup:**
1. Connect codebase-server để access affected code areas
2. Use git-server để analyze bug introduction history
3. Access dev-tools-server để run debugging và analysis tools

**Bug Information:**
- **Bug Description**: [MÔ_TẢ_BUG]
- **Reproduction Steps**: [BƯỚC_TÁI_TẠO]
- **Expected vs Actual**: [KẾT_QUẢ_MONG_ĐỢI_VS_THỰC_TẾ]

**PHASE 1: ROOT CAUSE ANALYSIS**
- Sử dụng MCP codebase-server để locate affected code areas
- Connect git-server để analyze when bug was introduced
- Use git blame để identify related changes
- Trace code execution path để understand failure point

**PHASE 2: IMPACT ASSESSMENT**
- Analyze scope của bug impact across codebase
- Identify all affected components và features
- Assess potential side effects của fix
- Determine regression testing requirements

**PHASE 3: FIX IMPLEMENTATION**
- Implement minimal, targeted fix
- Ensure fix doesn't break existing functionality
- Add defensive programming measures
- Include comprehensive logging for future debugging

**PHASE 4: VALIDATION**
- Create specific test cases để reproduce bug
- Verify fix resolves original issue
- Run regression test suite
- Perform integration testing

**Expected Output:**
1. **Root Cause Analysis**: Detailed explanation của bug origin
2. **Fix Implementation**: Minimal, targeted code changes
3. **Test Cases**: Specific tests để prevent regression
4. **Documentation**: Bug analysis và fix explanation

**Quality Gates:**
- [ ] Root cause clearly identified và documented
- [ ] Fix is minimal và targeted
- [ ] Regression tests added và passing
- [ ] No new issues introduced

**MCP Validation:**
- Verify comprehensive code analysis completed
- Confirm git history analysis provided insights
- Ensure debugging tools were effectively utilized
```

---

## 🔄 **SCENARIO 4: UPDATE TÍNH NĂNG CŨ**

### **MCP Requirements**
- ✅ Codebase Server (full access)
- ✅ Git Server (change impact analysis)
- ✅ Dev Tools Server (migration tools)

### **Prompt Template**
```
🔄 **SAFE FEATURE UPDATE**

**MCP Integration Setup:**
1. Connect codebase-server để analyze current implementation
2. Use git-server để understand feature evolution history
3. Access dev-tools-server để run impact analysis tools

**Update Information:**
- **Feature Name**: [TÊN_TÍNH_NĂNG]
- **Update Requirements**: [YÊU_CẦU_CẬP_NHẬT]
- **Business Impact**: [TÁC_ĐỘNG_BUSINESS]

**PHASE 1: CURRENT STATE ANALYSIS**
- Sử dụng MCP codebase-server để map current feature implementation
- Identify all components, dependencies, và integration points
- Analyze current usage patterns và performance metrics
- Document existing API contracts và data structures

**PHASE 2: IMPACT ASSESSMENT**
- Connect git-server để analyze feature change history
- Identify all dependent components và features
- Assess breaking change potential
- Plan backward compatibility strategy

**PHASE 3: MIGRATION STRATEGY**
- Design phased update approach
- Implement feature flags for gradual rollout
- Create migration scripts for data/config changes
- Plan rollback procedures

**PHASE 4: IMPLEMENTATION**
- Implement updates with backward compatibility
- Add comprehensive monitoring và logging
- Create A/B testing framework if needed
- Ensure graceful degradation capabilities

**Expected Output:**
1. **Migration Plan**: Step-by-step update strategy
2. **Updated Implementation**: Backward-compatible code
3. **Monitoring Setup**: Comprehensive observability
4. **Rollback Plan**: Emergency procedures

**Quality Gates:**
- [ ] Impact analysis completed và documented
- [ ] Backward compatibility maintained
- [ ] Migration strategy tested
- [ ] Rollback procedures verified

**MCP Validation:**
- Confirm comprehensive current state analysis
- Verify impact assessment covered all dependencies
- Ensure migration tools properly configured
```

---

## 🏗️ **SCENARIO 5: REFACTOR**

### **MCP Requirements**
- ✅ Codebase Server (full access)
- ✅ Git Server (refactoring history)
- ✅ Dev Tools Server (code analysis tools)

### **Prompt Template**
```
🏗️ **SYSTEMATIC CODE REFACTORING**

**MCP Integration Setup:**
1. Connect codebase-server để analyze code quality metrics
2. Use git-server để understand refactoring patterns
3. Access dev-tools-server để run static analysis tools

**Refactoring Target:**
- **Component/Module**: [TÊN_COMPONENT]
- **Refactoring Goals**: [MỤC_TIÊU_REFACTOR]
- **Quality Metrics**: [METRICS_CẦN_CẢI_THIỆN]

**PHASE 1: CODE QUALITY ANALYSIS**
- Sử dụng MCP dev-tools-server để run comprehensive code analysis
- Identify code smells, complexity hotspots, và duplication
- Analyze test coverage và identify untested areas
- Document current performance characteristics

**PHASE 2: REFACTORING STRATEGY**
- Connect git-server để study successful refactoring patterns
- Plan incremental refactoring approach
- Identify safe refactoring boundaries
- Design comprehensive test strategy

**PHASE 3: INCREMENTAL REFACTORING**
- Implement refactoring in small, safe steps
- Maintain 100% test coverage throughout process
- Verify functionality after each refactoring step
- Document architectural improvements

**PHASE 4: VALIDATION**
- Run comprehensive test suite after each change
- Verify performance improvements
- Ensure no regression in functionality
- Update documentation to reflect changes

**Expected Output:**
1. **Refactored Code**: Improved, maintainable implementation
2. **Quality Metrics**: Before/after comparison
3. **Test Suite**: Enhanced test coverage
4. **Documentation**: Updated architectural docs

**Quality Gates:**
- [ ] Code quality metrics improved
- [ ] Test coverage maintained/improved
- [ ] No functionality regression
- [ ] Performance maintained/improved

**MCP Validation:**
- Verify code analysis tools provided comprehensive insights
- Confirm refactoring followed established patterns
- Ensure validation tools confirmed improvements
```

---

## 🔍 **SCENARIO 6: PHÂN TÍCH TÍNH NĂNG & LUỒNG**

### **MCP Requirements**
- ✅ Codebase Server (full access)
- ✅ Git Server (feature evolution)
- ✅ Documentation Server (feature specs)

### **Prompt Template**
```
🔍 **COMPREHENSIVE FEATURE FLOW ANALYSIS**

**MCP Integration Setup:**
1. Connect codebase-server để trace complete feature implementation
2. Use git-server để understand feature development history
3. Access docs-server để correlate với specifications

**Feature Analysis Target:**
- **Feature Name**: [TÊN_TÍNH_NĂNG]
- **Analysis Scope**: [PHẠM_VI_PHÂN_TÍCH]
- **Focus Areas**: [ĐIỂM_QUAN_TÂM_CHÍNH]

**PHASE 1: FEATURE MAPPING**
- Sử dụng MCP codebase-server để identify all feature components
- Trace complete user journey through codebase
- Map data flow từ input đến output
- Identify all integration points và dependencies

**PHASE 2: FLOW ANALYSIS**
- Document step-by-step execution flow
- Identify decision points và branching logic
- Analyze error handling và edge cases
- Map performance bottlenecks và optimization opportunities

**PHASE 3: HISTORICAL EVOLUTION**
- Connect git-server để analyze feature development timeline
- Understand design decisions và trade-offs made
- Identify patterns of change và maintenance areas
- Extract lessons learned từ feature evolution

**PHASE 4: COMPREHENSIVE DOCUMENTATION**
- Create detailed flow diagrams
- Document API contracts và data structures
- Identify improvement opportunities
- Provide recommendations for optimization

**Expected Output:**
1. **Flow Diagrams**: Visual representation của feature flow
2. **Technical Documentation**: Comprehensive feature analysis
3. **Performance Analysis**: Bottlenecks và optimization opportunities
4. **Improvement Recommendations**: Actionable enhancement suggestions

**Quality Gates:**
- [ ] Complete feature flow mapped và documented
- [ ] All integration points identified
- [ ] Performance characteristics analyzed
- [ ] Improvement opportunities documented

**MCP Validation:**
- Confirm complete codebase analysis performed
- Verify historical analysis provided valuable insights
- Ensure documentation correlation completed
```

---

## 📚 **BEST PRACTICES**

### **MCP Integration Guidelines**
1. **Always verify server connections** before starting analysis
2. **Use appropriate access levels** for each server type
3. **Validate data completeness** from MCP servers
4. **Handle connection failures gracefully**
5. **Document MCP server dependencies** for each prompt

### **Quality Assurance**
1. **Implement validation checkpoints** at each phase
2. **Maintain comprehensive test coverage**
3. **Document all decisions và trade-offs**
4. **Follow established naming conventions**
5. **Ensure backward compatibility** when possible

### **Risk Mitigation**
1. **Always create backups** before major changes
2. **Implement feature flags** for new functionality
3. **Plan rollback procedures** for all updates
4. **Monitor system health** during changes
5. **Validate changes** in staging environment first

---

## 🚨 **TROUBLESHOOTING**

### **Common MCP Issues**
```bash
# Server connection failed
mcp-client reconnect <server-name>

# Incomplete data access
mcp-client verify-permissions <server-name>

# Performance issues
mcp-client optimize-connection <server-name>
```

### **Quality Gate Failures**
- **Test Coverage Below Threshold**: Add missing tests before proceeding
- **Performance Regression**: Profile và optimize before deployment
- **Breaking Changes Detected**: Implement backward compatibility
- **Documentation Incomplete**: Update docs before finalizing

---

## 🎯 **SUCCESS METRICS**

### **Quantitative Goals**
- **Analysis Completeness**: 100% coverage của target areas
- **Quality Improvement**: Measurable metrics enhancement
- **Time Efficiency**: 50% reduction in analysis time
- **Error Reduction**: 90% fewer issues in production

### **Qualitative Benefits**
- **Better Understanding**: Comprehensive system knowledge
- **Improved Maintainability**: Cleaner, more organized code
- **Enhanced Collaboration**: Better documentation và knowledge sharing
- **Reduced Risk**: Systematic approach to changes

---

**🚀 Result: Comprehensive prompt collection với MCP integration, ready for immediate use trong development workflows với measurable quality improvements và risk mitigation.**
