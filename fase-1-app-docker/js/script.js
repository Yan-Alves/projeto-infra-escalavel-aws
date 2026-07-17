// Função para mostrar status do container
function showStatus() {
    const statusSection = document.getElementById('status');
    if (statusSection) {
        statusSection.scrollIntoView({ behavior: 'smooth' });
    }
    updateStatus();
}

// Função para mostrar informações do sistema
function showInfo() {
    const timestamp = new Date().toLocaleString('pt-BR');
    const info = `
🐳 Container Docker: Ativo
⚡ Servidor: Nginx Alpine
🌐 Porta: 80
📅 Deploy Atualizado: ${timestamp}
☁️ Ambiente Cloud: (ALB + ASG)
🔄 Status da Infraestrutura: Online e Escalável
    `;
    alert(info);
}

// Função para simular a verificação de status em tempo real
function updateStatus() {
    const containerStatus = document.getElementById('container-status');
    const serverStatus = document.getElementById('server-status');
    const environment = document.getElementById('environment');
    
    setTimeout(() => {
        if (containerStatus) {
            containerStatus.textContent = 'ALB Ativo';
            containerStatus.className = 'status-value active';
        }
        if (serverStatus) {
            serverStatus.textContent = 'Auto Scaling OK';
            serverStatus.className = 'status-value active';
        }
        if (environment) {
            environment.textContent = 'AWS Multi-AZ';
            environment.className = 'status-value active';
        }
    }, 800);
}

// Inicialização quando a página carregar
document.addEventListener('DOMContentLoaded', function() {
    console.log('🚀 Projeto Infraestrutura Escalável - Site carregado com sucesso!');
    console.log('🐳 Containers Docker integrados a frota AWS');
    console.log('⚡ Nginx pronto para servir requisições via Load Balancer');
    
    // Smooth scroll para links de navegação
    const navLinks = document.querySelectorAll('.nav-link');
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const targetId = this.getAttribute('href').substring(1);
            const targetElement = document.getElementById(targetId);
            
            if (targetElement) {
                targetElement.scrollIntoView({ behavior: 'smooth' });
            }
        });
    });
});