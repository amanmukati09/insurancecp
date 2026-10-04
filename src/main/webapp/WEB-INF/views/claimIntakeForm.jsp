<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <title>File a New Claim (FNOL)</title>
    <style>
        body { font-family: Arial, Helvetica, sans-serif; margin: 2em; }
        h1 { font-size: 1.4em; }
        form { max-width: 480px; }
        .field { margin-bottom: 1em; }
        label { display: block; font-weight: bold; margin-bottom: 0.25em; }
        select, input[type="date"], textarea { width: 100%; padding: 0.4em; box-sizing: border-box; }
        .error { color: #b30000; font-size: 0.9em; margin-top: 0.25em; }
        .general-error { color: #b30000; border: 1px solid #b30000; background: #fdecea; padding: 0.75em; margin-bottom: 1em; }
        button { padding: 0.5em 1.5em; }
    </style>
</head>
<body>
<h1>File a New Claim (First Notice of Loss)</h1>

<c:if test="${not empty errorMessage}">
    <div class="general-error">${errorMessage}</div>
</c:if>

<form action="${pageContext.request.contextPath}/claims/new" method="post">

    <div class="field">
        <label for="claimantId">Claimant</label>
        <select id="claimantId" name="claimantId">
            <option value="">-- Select claimant --</option>
            <c:forEach var="claimant" items="${claimants}">
                <option value="${claimant.claimantId}"
                    <c:if test="${fnolForm.claimantId == claimant.claimantId}">selected="selected"</c:if>>
                    ${claimant.firstName} ${claimant.lastName}
                </option>
            </c:forEach>
        </select>
        <c:if test="${not empty fieldErrors['claimantId']}">
            <div class="error">${fieldErrors['claimantId']}</div>
        </c:if>
    </div>

    <div class="field">
        <label for="policyReferenceId">Policy Reference</label>
        <select id="policyReferenceId" name="policyReferenceId">
            <option value="">-- Select policy --</option>
            <c:forEach var="policy" items="${policyReferences}">
                <option value="${policy.policyReferenceId}"
                    <c:if test="${fnolForm.policyReferenceId == policy.policyReferenceId}">selected="selected"</c:if>>
                    ${policy.policyNumber} (${policy.policyType})
                </option>
            </c:forEach>
        </select>
        <c:if test="${not empty fieldErrors['policyReferenceId']}">
            <div class="error">${fieldErrors['policyReferenceId']}</div>
        </c:if>
    </div>

    <div class="field">
        <label for="lossDate">Loss Date</label>
        <input type="date" id="lossDate" name="lossDate" value="${fnolForm.lossDate}" />
        <c:if test="${not empty fieldErrors['lossDate']}">
            <div class="error">${fieldErrors['lossDate']}</div>
        </c:if>
    </div>

    <div class="field">
        <label for="lossDescription">Loss Description</label>
        <textarea id="lossDescription" name="lossDescription" rows="4">${fnolForm.lossDescription}</textarea>
        <c:if test="${not empty fieldErrors['lossDescription']}">
            <div class="error">${fieldErrors['lossDescription']}</div>
        </c:if>
    </div>

    <button type="submit">Submit Claim</button>
</form>
</body>
</html>
