css_code = """
/* ------------------------------------------------------------- */
/* 8. SOFTWARE SUPPORT SECTION                                   */
/* ------------------------------------------------------------- */
.software-support-section {
    background-color: var(--clr-dark-bg);
    color: var(--clr-text-light);
    padding: 100px 0;
    position: relative;
    border-top: 1px solid rgba(255, 255, 255, 0.05);
}

.software-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 30px;
    margin-top: 50px;
}

.software-card {
    background: var(--clr-dark-card);
    border: 1px solid rgba(255, 255, 255, 0.05);
    border-radius: var(--border-radius-md);
    padding: 30px;
    transition: var(--transition-fast);
}

.software-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
    border-color: rgba(139, 92, 246, 0.3);
}

.software-header {
    display: flex;
    align-items: center;
    gap: 15px;
    margin-bottom: 25px;
}

.software-icon {
    font-size: 1.8rem;
    color: var(--clr-primary);
    background: rgba(139, 92, 246, 0.1);
    padding: 15px;
    border-radius: var(--border-radius-sm);
    width: 60px;
    height: 60px;
    display: flex;
    align-items: center;
    justify-content: center;
}

.software-header h3 {
    font-family: var(--font-heading);
    font-size: 1.4rem;
    font-weight: 700;
}

.software-features {
    display: flex;
    flex-direction: column;
    gap: 15px;
}

.software-features li {
    display: flex;
    align-items: center;
    gap: 12px;
    color: var(--clr-text-light-muted);
    font-size: 0.95rem;
}

.software-features li::before {
    content: "■";
    color: var(--clr-primary);
    font-size: 0.6rem;
}
"""

with open('landing_page/style.css', 'a', encoding='utf-8') as f:
    f.write('\\n' + css_code + '\\n')
