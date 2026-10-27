local addonName, Root = ...
Root.Auc = Root.Auc or {}
local NS = Root.Auc

function NS:OnPlayerLogin()
    if NS.History then
        NS.History:Prune()
    end
    if NS.Scanner then
        NS.Scanner:Create()
    end
    if NS.Tooltip then
        NS.Tooltip:Create()
    end
    if NS.Window then
        NS.Window:Create()
    end
end
