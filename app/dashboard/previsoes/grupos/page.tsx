import { VisualDataSourceBanner } from "../../../../components/world-cup/VisualDataSourceBanner.tsx";
import { VisualSimulatorShell } from "../../../../components/world-cup/VisualSimulatorShell.tsx";
import { VisualWorldCupSimulator } from "../../../../components/world-cup/VisualWorldCupSimulator.tsx";
import { getVisualGroupsForSimulator } from "../../../../lib/fifa/visualOfficialDataAdapter.ts";

export const dynamic = "force-dynamic";

export default async function GroupPredictionsVisualPage() {
  const simulatorData = await getVisualGroupsForSimulator();

  return (
    <VisualSimulatorShell activeSection="groups">
      <VisualDataSourceBanner message={simulatorData.message} source={simulatorData.source} />
      <VisualWorldCupSimulator groups={simulatorData.groups} />
    </VisualSimulatorShell>
  );
}
