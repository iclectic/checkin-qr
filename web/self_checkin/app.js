(() => {
  const config = window.CHECKIN_CONFIG || {};
  const form = document.getElementById('checkin-form');
  const nameInput = document.getElementById('name-input');
  const emailInput = document.getElementById('email-input');
  const companyInput = document.getElementById('company-input');
  const submitButton = document.getElementById('submit-button');
  const statusBox = document.getElementById('status-box');
  const eventBadge = document.getElementById('event-badge');
  const helper = document.getElementById('event-helper');
  const extrasFields = document.getElementById('extras-fields');
  const companyField = document.getElementById('company-field');
  const logo = document.getElementById('logo');

  const setStatus = (message, isError = false) => {
    statusBox.textContent = message;
    statusBox.classList.toggle('error', isError);
    statusBox.style.display = 'block';
  };

  const clearStatus = () => {
    statusBox.textContent = '';
    statusBox.style.display = 'none';
  };

  const setLoading = (loading) => {
    submitButton.disabled = loading;
    submitButton.textContent = loading ? 'Submitting...' : 'Check me in';
  };

  const query = new URLSearchParams(window.location.search);
  const eventId = query.get('eventId');
  const eventCode = query.get('eventCode');

  if (config.title) {
    document.getElementById('page-title').textContent = config.title;
  }
  if (config.subtitle) {
    document.getElementById('page-subtitle').textContent = config.subtitle;
  }
  if (config.footerNote) {
    document.getElementById('footer-note').textContent = config.footerNote;
  }
  if (config.logoUrl && logo) {
    logo.src = config.logoUrl;
    logo.style.display = 'block';
  }

  if (!config.enableExtras) {
    extrasFields.style.display = 'none';
    companyField.style.display = 'none';
  }

  if (!config.requireName) {
    nameInput.required = false;
    nameInput.placeholder = 'Name (optional)';
  }

  if (!eventId || !eventCode) {
    form.style.display = 'none';
    helper.textContent = 'Missing event details. Please scan the QR again.';
    setStatus('Invalid or missing event token.', true);
    return;
  }

  eventBadge.textContent = `Event ${eventId.slice(0, 6)}...${eventId.slice(-4)}`;

  if (!config.supabaseUrl || !config.supabaseAnonKey) {
    form.style.display = 'none';
    setStatus('Check-in service is not configured. Please contact the host.', true);
    return;
  }

  if (!window.supabase) {
    form.style.display = 'none';
    setStatus('Check-in service failed to load. Please try again later.', true);
    return;
  }

  const client = supabase.createClient(
    config.supabaseUrl,
    config.supabaseAnonKey,
  );

  const generateId = () => {
    if (window.crypto && crypto.randomUUID) {
      return crypto.randomUUID();
    }
    return `id-${Math.random().toString(16).slice(2)}${Date.now().toString(16)}`;
  };

  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    clearStatus();

    const nameValue = nameInput.value.trim();
    if (config.requireName && !nameValue) {
      setStatus('Please enter your name.', true);
      return;
    }

    setLoading(true);

    const payload = {
      id: generateId(),
      event_id: eventId,
      event_code: eventCode,
      attendee_name: nameValue || null,
      attendee_email: emailInput.value.trim() || null,
      attendee_company: companyInput.value.trim() || null,
      method: 'self',
      timestamp: new Date().toISOString(),
    };

    try {
      const { error } = await client
        .from(config.tableName || 'check_ins')
        .insert(payload);

      if (error) {
        throw error;
      }

      form.reset();
      setStatus('You are checked in. Thanks for coming!');
    } catch (err) {
      setStatus(
        err?.message || 'Unable to submit check-in. Please try again.',
        true,
      );
    } finally {
      setLoading(false);
    }
  });
})();
